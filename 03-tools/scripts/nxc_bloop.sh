#!/usr/bin/env bash
set -uo pipefail

SCRIPT_NAME="$(basename "$0")"

usage() {
    cat <<EOF
Usage:
  $SCRIPT_NAME -t <target> -P <protocols> [auth options] [credential mode] [options]

Targets:
  -t, --target <ip|range|file>         Single target, range, or target file accepted by nxc

Protocols:
  -P, --protocols <p1,p2,...>          Example: smb,winrm,ldap
  Supported: smb, winrm, ldap, mssql, ssh, ftp, vnc, wmi, rdp
      --all                            Run all supported protocols

Credential modes (choose one):
  -u, --username <user>                Single username
  -p, --password <pass>                Single password
  -U, --userfile <file>                File with usernames
  -W, --passfile <file>                File with passwords
  -C, --combo-file <file>              File with exact combos: username:password
  -k, --key-file <file>                SSH private key file (SSH only; implies -P ssh)
      --passphrase <phrase>            Passphrase for the SSH private key (optional)
      --ssh-port <port>                SSH port to target (default: 22)

Auth context:
      --auth domain                    Use domain auth
      --auth local                     Use --local-auth
      --local-auth                     Shorthand for --auth local
  -d, --domain <domain>                Domain value for domain auth

Options:
      --timeout <sec>                  Per-command timeout (default: 30)
      --continue-on-success            Add --continue-on-success where supported
      --log <file>                     Append raw output to a log file
      --log-markdown <file>            Append output wrapped in a bash code block (Obsidian-ready)
      --successes-only                 Print/log only successful hits ([+] lines and Pwn3d!, filters [-] noise)
      --dry-run                        Print commands without executing
  -h, --help                           Show this help

Examples:
  $SCRIPT_NAME -t 192.168.1.10 -P smb,winrm -u alice -p 'Password123!'
  $SCRIPT_NAME -t 192.168.1.10 -P smb,ldap --auth domain -d corp.local -U users.txt -p 'Winter2024!'
  $SCRIPT_NAME -t 192.168.1.10 -P smb,wmi --local-auth -u administrator -W passwords.txt
  $SCRIPT_NAME -t 192.168.1.10 -P smb,winrm --auth domain -d corp.local -C combos.txt
  $SCRIPT_NAME -t targets.txt -P ssh -u anita -k anita/id_ecdsa --passphrase 'password'
  $SCRIPT_NAME -t targets.txt -P ssh -U users.txt -k anita/id_ecdsa
  $SCRIPT_NAME -t ../targets.txt --all -C creds.txt --local-auth --continue-on-success
EOF
}

die() {
    echo "[!] $*" >&2
    exit 1
}

log() {
    local msg="$1"
    echo "$msg"
    if [[ -n "${LOG_FILE:-}" ]]; then
        echo "$msg" >> "$LOG_FILE"
    fi
}

trim() {
    local s="$1"
    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"
    printf '%s' "$s"
}

# NetExec supports: smb, winrm, ldap, mssql, ssh, ftp, vnc, wmi, rdp
ALL_PROTOCOLS=(smb winrm ldap mssql ssh ftp vnc wmi rdp)

is_supported_proto() {
    local proto="$1"
    case "$proto" in
        smb|winrm|ldap|mssql|ssh|ftp|vnc|wmi|rdp) return 0 ;;
        *) return 1 ;;
    esac
}

# Protocols that accept -d <domain> for domain-context auth
supports_domain_flag() {
    local proto="$1"
    case "$proto" in
        smb|ldap|winrm|mssql|wmi|rdp) return 0 ;;
        *) return 1 ;;
    esac
}

# Protocols that accept --local-auth
supports_local_flag() {
    local proto="$1"
    case "$proto" in
        smb|winrm|mssql|wmi|rdp) return 0 ;;
        *) return 1 ;;
    esac
}

run_cmd() {
    local proto="$1"
    local user="$2"
    local pass="$3"   # may be empty when using key-file mode

    local -a cmd

    # Key-file mode: only valid for SSH
    if [[ -n "$KEY_FILE" ]]; then
        cmd=(nxc ssh "$TARGET" -u "$user" --key-file "$KEY_FILE")
        [[ -n "$SSH_PORT" ]] && cmd+=(--port "$SSH_PORT")
        local _kf_pass="${PASSPHRASE:-$PASSWORD}"; [[ -n "$_kf_pass" ]] && cmd+=(-p "$_kf_pass")
    else
        cmd=(nxc "$proto" "$TARGET" -u "$user" -p "$pass")

        if [[ "$AUTH_TYPE" == "domain" ]] && supports_domain_flag "$proto"; then
            [[ -n "$DOMAIN" ]] || die "Domain auth selected but no domain provided."
            cmd+=(-d "$DOMAIN")
        elif [[ "$AUTH_TYPE" == "local" ]] && supports_local_flag "$proto"; then
            cmd+=(--local-auth)
        fi

        # Pass custom port for SSH password-mode too
        [[ -n "$SSH_PORT" && "$proto" == "ssh" ]] && cmd+=(--port "$SSH_PORT")
    fi

    if [[ "$CONTINUE_ON_SUCCESS" -eq 1 ]]; then
        cmd+=(--continue-on-success)
    fi

    log ""
    log "[*] Protocol: $proto | User: $user"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log "[DRY-RUN] $(printf '%q ' "${cmd[@]}")"
        return 0
    fi

    # Capture output and exit code separately.
    # nxc exits non-zero on auth failure even for reachable hosts, so we must not
    # suppress output on any non-zero exit — only exit 124 means a real timeout.
    local raw_output exit_code
    raw_output="$(timeout "$TIMEOUT" "${cmd[@]}" 2>&1)"
    exit_code=$?
    if [[ $exit_code -eq 124 ]]; then
        [[ "$SUCCESSES_ONLY" -eq 0 ]] && log "[!] $proto timed out (>${TIMEOUT}s)"
        return 0
    fi

    local display_output
    if [[ "$SUCCESSES_ONLY" -eq 1 ]]; then
        # Keep [+] lines AND any line containing Pwn3d!; strip [-] noise
        display_output="$(echo "$raw_output" | grep -E '^\[?\+\]|Pwn3d!')"
    else
        display_output="$raw_output"
    fi

    [[ -z "$display_output" ]] && return 0

    echo "$display_output"

    if [[ -n "${LOG_FILE:-}" ]]; then
        echo "$display_output" >> "$LOG_FILE"
    fi

    if [[ -n "${LOG_MARKDOWN:-}" ]]; then
        echo "$display_output" >> "$LOG_MARKDOWN"
    fi
}

# Defaults
TARGET=""
PROTO_LIST=""
USE_ALL_PROTOCOLS=0
USERNAME=""
PASSWORD=""
USERFILE=""
PASSFILE=""
COMBO_FILE=""
KEY_FILE=""
PASSPHRASE=""
SSH_PORT=""
AUTH_TYPE=""
DOMAIN=""
TIMEOUT=30
CONTINUE_ON_SUCCESS=0
LOG_FILE=""
LOG_MARKDOWN=""
SUCCESSES_ONLY=0
DRY_RUN=0

# Parse args
while [[ $# -gt 0 ]]; do
    case "$1" in
        -t|--target)            TARGET="$2";       shift 2 ;;
        --all)                  USE_ALL_PROTOCOLS=1; shift ;;
        -P|--protocols)         PROTO_LIST="$2";   shift 2 ;;
        -u|--username)          USERNAME="$2";     shift 2 ;;
        -p|--password)          PASSWORD="$2";     shift 2 ;;
        -U|--userfile)          USERFILE="$2";     shift 2 ;;
        -W|--passfile)          PASSFILE="$2";     shift 2 ;;
        -C|--combo-file)        COMBO_FILE="$2";   shift 2 ;;
        -k|--key-file)          KEY_FILE="$2";     shift 2 ;;
        --passphrase)           PASSPHRASE="$2";   shift 2 ;;
        --ssh-port)             SSH_PORT="$2";     shift 2 ;;
        --auth)                 AUTH_TYPE="$2";    shift 2 ;;
        --local-auth)           AUTH_TYPE="local"; shift ;;
        -d|--domain)            DOMAIN="$2";       shift 2 ;;
        --timeout)              TIMEOUT="$2";      shift 2 ;;
        --continue-on-success)  CONTINUE_ON_SUCCESS=1; shift ;;
        --log)                  LOG_FILE="$2";     shift 2 ;;
        --log-markdown)         LOG_MARKDOWN="$2"; shift 2 ;;
        --successes-only)       SUCCESSES_ONLY=1;  shift ;;
        --dry-run)              DRY_RUN=1;         shift ;;
        -h|--help)              usage; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -n "$TARGET" ]] || die "Target is required."

# --all expands to every supported protocol; -P is then optional
if [[ "$USE_ALL_PROTOCOLS" -eq 1 ]]; then
    PROTO_LIST="$(IFS=','; echo "${ALL_PROTOCOLS[*]}")"
fi

# Key-file validation (must run before the PROTO_LIST required check so auto-ssh can fire)
if [[ -n "$KEY_FILE" ]]; then
    [[ -f "$KEY_FILE" ]] || die "Key file not found: $KEY_FILE"

    # key-file is SSH-only; reject if user also asked for non-SSH protocols
    if [[ -n "$PROTO_LIST" ]]; then
        IFS=',' read -ra _kf_protos <<< "$PROTO_LIST"
        for _p in "${_kf_protos[@]}"; do
            _p="$(trim "$_p")"
            [[ "$_p" == "ssh" ]] || die "--key-file is SSH-only; remove '$_p' from -P or drop -P to auto-select ssh."
        done
    fi

    # Auto-set protocol to ssh when -P was omitted
    [[ -z "$PROTO_LIST" ]] && PROTO_LIST="ssh"

fi

[[ -n "$PROTO_LIST" ]] || die "Protocols are required. Use -P <protos> or --all."

IFS=',' read -ra SERVICES <<< "$PROTO_LIST"
for svc in "${SERVICES[@]}"; do
    svc="$(trim "$svc")"
    is_supported_proto "$svc" || die "Unsupported protocol: $svc. Supported: smb, winrm, ldap, mssql, ssh, ftp, vnc, wmi, rdp"
done

if [[ -n "$AUTH_TYPE" ]] && [[ "$AUTH_TYPE" != "domain" && "$AUTH_TYPE" != "local" ]]; then
    die "Auth type must be 'domain' or 'local'."
fi

MODE_COUNT=0
[[ -n "$COMBO_FILE" ]] && MODE_COUNT=$((MODE_COUNT + 1))
[[ -n "$KEY_FILE"   ]] && MODE_COUNT=$((MODE_COUNT + 1))

if [[ -n "$USERNAME" || -n "$PASSWORD" || -n "$USERFILE" || -n "$PASSFILE" ]]; then
    # In key-file mode a username/userfile is expected — don't double-count it
    if [[ -z "$KEY_FILE" ]]; then
        MODE_COUNT=$((MODE_COUNT + 1))
    fi
fi

[[ "$MODE_COUNT" -eq 1 ]] || die "Choose exactly one credential mode: single/list (-u/-p/-U/-W), combo-file (-C), or key-file (-k)."

if [[ -n "$COMBO_FILE" ]]; then
    [[ -f "$COMBO_FILE" ]] || die "Combo file not found: $COMBO_FILE"
elif [[ -n "$KEY_FILE" ]]; then
    # Key-file mode: need a username or userfile; password not required
    [[ -n "$USERNAME" || -n "$USERFILE" ]] || die "Provide --username or --userfile with --key-file"
    [[ -z "$USERFILE" || -f "$USERFILE" ]] || die "User file not found: $USERFILE"
else
    [[ -n "$USERNAME" || -n "$USERFILE" ]] || die "Provide --username or --userfile"
    [[ -n "$PASSWORD" || -n "$PASSFILE" ]] || die "Provide --password or --passfile"
    [[ -z "$USERFILE" || -f "$USERFILE" ]] || die "User file not found: $USERFILE"
    [[ -z "$PASSFILE" || -f "$PASSFILE" ]] || die "Password file not found: $PASSFILE"
fi

# Build user/password arrays for list modes
declare -a USERS PASSWORDS
USERS=()
PASSWORDS=()

if [[ -z "$COMBO_FILE" ]]; then
    if [[ -n "$USERNAME" ]]; then
        USERS+=("$USERNAME")
    elif [[ -n "$USERFILE" ]]; then
        mapfile -t USERS < <(grep -v '^[[:space:]]*$' "$USERFILE")
    fi

    if [[ -z "$KEY_FILE" ]]; then
        if [[ -n "$PASSWORD" ]]; then
            PASSWORDS+=("$PASSWORD")
        else
            mapfile -t PASSWORDS < <(grep -v '^[[:space:]]*$' "$PASSFILE")
        fi
    fi
fi

# Open markdown code block if --log-markdown is set
if [[ -n "$LOG_MARKDOWN" ]]; then
    {
        echo "# nxc spray — $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Target: \`$TARGET\` | Protocols: \`$PROTO_LIST\`"
        echo ""
        echo '```bash'
    } >> "$LOG_MARKDOWN"
fi

# Execution
if [[ -n "$COMBO_FILE" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" =~ ^# ]] && continue

        user="$(trim "${line%%:*}")"
        pass="$(trim "${line#*:}")"

        [[ -z "$user" || "$user" == "$line" ]] && die "Invalid combo line (missing or leading colon): $line"

        for proto in "${SERVICES[@]}"; do
            proto="$(trim "$proto")"
            run_cmd "$proto" "$user" "$pass"
        done
    done < "$COMBO_FILE"
elif [[ -n "$KEY_FILE" ]]; then
    # Key-file mode: no password dimension — just iterate users × protocols
    for user in "${USERS[@]}"; do
        user="$(trim "$user")"
        [[ -z "$user" ]] && continue

        for proto in "${SERVICES[@]}"; do
            proto="$(trim "$proto")"
            run_cmd "$proto" "$user" ""
        done
    done
else
    for user in "${USERS[@]}"; do
        user="$(trim "$user")"
        [[ -z "$user" ]] && continue

        for pass in "${PASSWORDS[@]}"; do
            [[ -z "$pass" ]] && continue

            for proto in "${SERVICES[@]}"; do
                proto="$(trim "$proto")"
                run_cmd "$proto" "$user" "$pass"
            done
        done
    done
fi

# Close markdown code block
if [[ -n "$LOG_MARKDOWN" ]]; then
    echo '```' >> "$LOG_MARKDOWN"
    echo "" >> "$LOG_MARKDOWN"
    log "[*] Markdown log written to: $LOG_MARKDOWN"
fi