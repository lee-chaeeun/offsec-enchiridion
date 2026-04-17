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
  Supported: smb, winrm, ldap, mssql, ssh, ftp, vnc, wmi

Credential modes (choose one):
  -u, --username <user>                Single username
  -p, --password <pass>                Single password
  -U, --userfile <file>                File with usernames
  -W, --passfile <file>                File with passwords
  -C, --combo-file <file>              File with exact combos: username:password

Auth context:
      --auth domain                    Use domain auth
      --auth local                     Use --local-auth
  -d, --domain <domain>                Domain value for domain auth

Options:
      --timeout <sec>                  Per-command timeout (default: 30)
      --continue-on-success            Add --continue-on-success where supported
      --log <file>                     Append output to a log file
      --dry-run                        Print commands without executing
  -h, --help                           Show this help

Examples:
  $SCRIPT_NAME -t 192.168.1.10 -P smb,winrm -u alice -p 'Password123!'
  $SCRIPT_NAME -t 192.168.1.10 -P smb,ldap --auth domain -d corp.local -U users.txt -p 'Winter2024!'
  $SCRIPT_NAME -t 192.168.1.10 -P smb,wmi --auth local -u administrator -W passwords.txt
  $SCRIPT_NAME -t 192.168.1.10 -P smb,winrm --auth domain -d corp.local -C combos.txt
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

# NetExec supports: smb, winrm, ldap, mssql, ssh, ftp, vnc, wmi
# RDP was dropped from nxc; VNC and WMI are new additions.
is_supported_proto() {
    local proto="$1"
    case "$proto" in
        smb|winrm|ldap|mssql|ssh|ftp|vnc|wmi) return 0 ;;
        *) return 1 ;;
    esac
}

# Protocols that accept -d <domain> for domain-context auth
supports_domain_flag() {
    local proto="$1"
    case "$proto" in
        smb|ldap|winrm|mssql|wmi) return 0 ;;
        *) return 1 ;;
    esac
}

# Protocols that accept --local-auth
supports_local_flag() {
    local proto="$1"
    case "$proto" in
        smb|winrm|mssql|wmi|ssh|ftp) return 0 ;;
        *) return 1 ;;
    esac
}

run_cmd() {
    local proto="$1"
    local user="$2"
    local pass="$3"

    local -a cmd
    cmd=(nxc "$proto" "$TARGET" -u "$user" -p "$pass")

    if [[ "$AUTH_TYPE" == "domain" ]] && supports_domain_flag "$proto"; then
        [[ -n "$DOMAIN" ]] || die "Domain auth selected but no domain provided."
        cmd+=(-d "$DOMAIN")
    elif [[ "$AUTH_TYPE" == "local" ]] && supports_local_flag "$proto"; then
        cmd+=(--local-auth)
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

    if [[ -n "${LOG_FILE:-}" ]]; then
        timeout "$TIMEOUT" "${cmd[@]}" | tee -a "$LOG_FILE" || log "[!] $proto check failed or timed out"
    else
        timeout "$TIMEOUT" "${cmd[@]}" || log "[!] $proto check failed or timed out"
    fi
}

# Defaults
TARGET=""
PROTO_LIST=""
USERNAME=""
PASSWORD=""
USERFILE=""
PASSFILE=""
COMBO_FILE=""
AUTH_TYPE=""
DOMAIN=""
TIMEOUT=30
CONTINUE_ON_SUCCESS=0
LOG_FILE=""
DRY_RUN=0

# Parse args
while [[ $# -gt 0 ]]; do
    case "$1" in
        -t|--target)            TARGET="$2";       shift 2 ;;
        -P|--protocols)         PROTO_LIST="$2";   shift 2 ;;
        -u|--username)          USERNAME="$2";     shift 2 ;;
        -p|--password)          PASSWORD="$2";     shift 2 ;;
        -U|--userfile)          USERFILE="$2";     shift 2 ;;
        -W|--passfile)          PASSFILE="$2";     shift 2 ;;
        -C|--combo-file)        COMBO_FILE="$2";   shift 2 ;;
        --auth)                 AUTH_TYPE="$2";    shift 2 ;;
        -d|--domain)            DOMAIN="$2";       shift 2 ;;
        --timeout)              TIMEOUT="$2";      shift 2 ;;
        --continue-on-success)  CONTINUE_ON_SUCCESS=1; shift ;;
        --log)                  LOG_FILE="$2";     shift 2 ;;
        --dry-run)              DRY_RUN=1;         shift ;;
        -h|--help)              usage; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

[[ -n "$TARGET" ]]    || die "Target is required."
[[ -n "$PROTO_LIST" ]] || die "Protocols are required."

IFS=',' read -ra SERVICES <<< "$PROTO_LIST"
for svc in "${SERVICES[@]}"; do
    svc="$(trim "$svc")"
    is_supported_proto "$svc" || die "Unsupported protocol: $svc. Supported: smb, winrm, ldap, mssql, ssh, ftp, vnc, wmi"
done

if [[ -n "$AUTH_TYPE" ]] && [[ "$AUTH_TYPE" != "domain" && "$AUTH_TYPE" != "local" ]]; then
    die "Auth type must be 'domain' or 'local'."
fi

MODE_COUNT=0
[[ -n "$COMBO_FILE" ]] && MODE_COUNT=$((MODE_COUNT + 1))

if [[ -n "$USERNAME" || -n "$PASSWORD" || -n "$USERFILE" || -n "$PASSFILE" ]]; then
    MODE_COUNT=$((MODE_COUNT + 1))
fi

[[ "$MODE_COUNT" -eq 1 ]] || die "Choose exactly one credential mode: single/list mode OR combo-file mode."

if [[ -n "$COMBO_FILE" ]]; then
    [[ -f "$COMBO_FILE" ]] || die "Combo file not found: $COMBO_FILE"
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
    else
        mapfile -t USERS < <(grep -v '^[[:space:]]*$' "$USERFILE")
    fi

    if [[ -n "$PASSWORD" ]]; then
        PASSWORDS+=("$PASSWORD")
    else
        mapfile -t PASSWORDS < <(grep -v '^[[:space:]]*$' "$PASSFILE")
    fi
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
