#!/usr/bin/env bash
# nmap_scan.sh — scan an IP range or targets file, one terminal window/tab per host
# Usage: ./nmap_scan.sh [ip_range|--targets targets.txt] [port_range] [mode] [--udp]
# Example: ./nmap_scan.sh 192.168.1.10-20 1-65353 tmux --udp
#          ./nmap_scan.sh --targets targets.txt 1-1024 tmux
# If no args given, runs interactively.

set -uo pipefail

# ── helpers ────────────────────────────────────────────────────────────────────

usage() {
  echo "Usage: $0 [ip_range|--targets FILE] [port_range] [mode] [--udp]"
  echo ""
  echo "  ip_range     e.g. 192.168.1.10-20"
  echo "  --targets    path to a newline-separated file of IPs (default: targets.txt)"
  echo "  port_range   e.g. 1-65353  (default: 1-65353)"
  echo "  mode         gnome | xfce4 | xterm | tmux | screen  (default: tmux)"
  echo "  --udp        also run a UDP scan (-sU) on common ports in a separate window"
  echo ""
  echo "Examples:"
  echo "  $0 192.168.111.137-145"
  echo "  $0 192.168.111.137-145 1-1024 xfce4 --udp"
  echo "  $0 --targets targets.txt 1-65353 tmux"
  echo "  $0 --targets /path/to/hosts.txt 1-1024 tmux --udp"
  exit 1
}

parse_range() {
  local input="$1"
  if [[ ! "$input" =~ ^([0-9]+\.[0-9]+\.[0-9]+)\.([0-9]+)-([0-9]+)$ ]]; then
    echo "ERROR: Invalid IP range format. Use e.g. 192.168.1.10-20" >&2
    exit 1
  fi
  PREFIX="${BASH_REMATCH[1]}"
  START="${BASH_REMATCH[2]}"
  END="${BASH_REMATCH[3]}"
  if (( START > END || END > 255 )); then
    echo "ERROR: Invalid range (start > end, or octet > 255)" >&2
    exit 1
  fi
  IPS=()
  for (( i=START; i<=END; i++ )); do
    IPS+=("${PREFIX}.${i}")
  done
}

load_targets_file() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "ERROR: Targets file '${file}' not found." >&2
    exit 1
  fi
  IPS=()
  while IFS= read -r line; do
    line="${line%%#*}"   # strip inline comments
    line="${line// /}"   # strip spaces
    [[ -z "$line" ]] && continue
    IPS+=("$line")
  done < "$file"
  if [[ ${#IPS[@]} -eq 0 ]]; then
    echo "ERROR: No valid IPs found in '${file}'." >&2
    exit 1
  fi
  echo "[*] Loaded ${#IPS[@]} targets from '${file}'."
}

pick_input_source() {
  echo ""
  echo "Select IP input source:"
  echo "  1) Enter an IP range manually   (e.g. 192.168.1.10-20)"
  echo "  2) Load from targets.txt"
  echo "  3) Load from a custom file path"
  echo ""
  read -rp "Choice [1-3, default=1]: " src_choice
  case "$src_choice" in
    2)
      INPUT_SOURCE="targets_default"
      ;;
    3)
      read -rp "Enter path to targets file: " TARGETS_FILE
      INPUT_SOURCE="targets_custom"
      ;;
    *)
      INPUT_SOURCE="range"
      ;;
  esac
}

pick_mode() {
  echo ""
  echo "Select terminal mode:"
  echo "  1) tmux        (recommended for Kali)"
  echo "  2) xfce4       (Kali default desktop)"
  echo "  3) gnome       (GNOME Terminal)"
  echo "  4) xterm       (plain xterm)"
  echo "  5) screen      (GNU screen)"
  echo ""
  read -rp "Choice [1-5, default=1]: " choice
  case "$choice" in
    2) MODE="xfce4" ;;
    3) MODE="gnome" ;;
    4) MODE="xterm" ;;
    5) MODE="screen" ;;
    *) MODE="tmux" ;;
  esac
}

pick_udp() {
  echo ""
  read -rp "Enable UDP scanning on common ports? [y/N]: " udp_choice
  case "$udp_choice" in
    [yY][eE][sS]|[yY]) UDP_SCAN=true ;;
    *) UDP_SCAN=false ;;
  esac
}

# Output directory — created immediately so realpath works inside run_tmux
OUTPUT_DIR="./nmap_scan_output"
mkdir -p "$OUTPUT_DIR"

setup_output_dir() {
  echo "[*] Scan output will be saved to $(realpath "$OUTPUT_DIR")/"
}

# Build the nmap command string for a given IP.
# TCP scan uses the user-specified port range with -sC -sV.
# UDP scan (if enabled) uses nmap's top 200 UDP ports with -sU -sV --version-intensity 0
# and runs in a separate window labelled "<ip>-udp".
# Both save plain-text output to ./nmap_scan_output/<last_octet>[_udp].txt
build_tcp_cmd() {
  local ip="$1"
  local octet="${ip##*.}"
  local outfile="${OUTPUT_DIR}/${octet}.txt"
  echo "sudo nmap -p ${PORTS} -sC -sV ${ip} -Pn -oN ${outfile}"
}

build_udp_cmd() {
  local ip="$1"
  local octet="${ip##*.}"
  local outfile="${OUTPUT_DIR}/${octet}_udp.txt"
  # --top-ports 200 covers the most common UDP services without taking forever.
  # Remove --top-ports and adjust to taste (e.g. -p U:53,67,68,69,111,123,161,500,4500).
  echo "sudo nmap -sU -sV --version-intensity 0 --top-ports 200 ${ip} -Pn -oN ${outfile}"
}

# ── modes ─────────────────────────────────────────────────────────────────────

make_window_script() {
  local ip="$1" nmap_cmd="$2" outfile="$3"
  local tmp
  tmp="$(mktemp /tmp/nmap_win_XXXXXX.sh)"
  cat > "$tmp" <<SCRIPT
#!/usr/bin/env bash
echo "[*] Starting: ${nmap_cmd}"
${nmap_cmd}
echo ""
echo "[*] Done. Output saved to ${outfile}"
read -rp "Press enter to close..."
SCRIPT
  chmod +x "$tmp"
  echo "[DEBUG] Created window script: $tmp" >&2
  echo "[DEBUG] Contents:" >&2
  cat "$tmp" >&2
  echo "$tmp"
}

run_tmux() {
  # Kill any stale session so tmux new-session never errors
  tmux kill-session -t nmap_scan 2>/dev/null || true

  local abs_out
  abs_out="$(realpath "$OUTPUT_DIR")"

  echo "[*] Launching tmux session 'nmap_scan' with ${#IPS[@]} host(s)..."
  echo "[*] Output folder: ${abs_out}"

  local first_window=true
  for ip in "${IPS[@]}"; do
    local octet="${ip##*.}"
    local outfile="${abs_out}/${octet}.txt"
    local tcp_cmd
    tcp_cmd="sudo nmap -p ${PORTS} -sC -sV ${ip} -Pn -oN ${outfile}"
    local script
    script="$(make_window_script "$ip" "$tcp_cmd" "$outfile")"

    if [[ "$first_window" == true ]]; then
      tmux new-session -d -s nmap_scan -n "$ip" "bash $script" || {
        echo "ERROR: tmux new-session failed." >&2; exit 1
      }
      first_window=false
    else
      tmux new-window -t nmap_scan -n "$ip" "bash $script"
    fi

    if [[ "$UDP_SCAN" == true ]]; then
      local udp_outfile="${abs_out}/${octet}_udp.txt"
      local udp_cmd
      udp_cmd="sudo nmap -sU -sV --version-intensity 0 --top-ports 200 ${ip} -Pn -oN ${udp_outfile}"
      local udp_script
      udp_script="$(make_window_script "$ip" "$udp_cmd" "$udp_outfile")"
      tmux new-window -t nmap_scan -n "${ip}-udp" "bash $udp_script"
    fi
  done

  echo "[*] Attaching — use Ctrl+b <number> to switch windows, Ctrl+b d to detach."
  tmux attach-session -t nmap_scan
}

run_screen() {
  echo "[*] Launching GNU screen session 'nmap_scan' with ${#IPS[@]} host(s)..."
  local first="${IPS[0]}"
  screen -dmS nmap_scan -t "$first" bash -c \
    "$(build_tcp_cmd "$first"); read -p 'Done. Press enter...'"
  if [[ "$UDP_SCAN" == true ]]; then
    screen -S nmap_scan -X screen -t "${first}-udp" bash -c \
      "$(build_udp_cmd "$first"); read -p 'Done. Press enter...'"
  fi
  for ip in "${IPS[@]:1}"; do
    screen -S nmap_scan -X screen -t "$ip" bash -c \
      "$(build_tcp_cmd "$ip"); read -p 'Done. Press enter...'"
    if [[ "$UDP_SCAN" == true ]]; then
      screen -S nmap_scan -X screen -t "${ip}-udp" bash -c \
        "$(build_udp_cmd "$ip"); read -p 'Done. Press enter...'"
    fi
  done
  echo "[*] Attaching — use Ctrl+a <number> to switch windows, Ctrl+a d to detach."
  screen -r nmap_scan
}

run_xfce4() {
  echo "[*] Opening xfce4-terminal tabs for ${#IPS[@]} host(s)..."
  local cmd="xfce4-terminal"
  for ip in "${IPS[@]}"; do
    cmd+=" --tab -T 'nmap ${ip}' -e \"bash -c '$(build_tcp_cmd "$ip"); read -p Done.\\\ Press\\\ enter...'\""
    if [[ "$UDP_SCAN" == true ]]; then
      cmd+=" --tab -T 'nmap ${ip} UDP' -e \"bash -c '$(build_udp_cmd "$ip"); read -p Done.\\\ Press\\\ enter...'\""
    fi
  done
  eval "$cmd" &
}

run_gnome() {
  echo "[*] Opening GNOME Terminal tabs for ${#IPS[@]} host(s)..."
  local cmd="gnome-terminal"
  for ip in "${IPS[@]}"; do
    cmd+=" --tab -- bash -c \"$(build_tcp_cmd "$ip"); exec bash\""
    if [[ "$UDP_SCAN" == true ]]; then
      cmd+=" --tab -- bash -c \"$(build_udp_cmd "$ip"); exec bash\""
    fi
  done
  eval "$cmd" &
}

run_xterm() {
  echo "[*] Opening xterm windows for ${#IPS[@]} host(s)..."
  for ip in "${IPS[@]}"; do
    xterm -T "nmap ${ip}" -e \
      "$(build_tcp_cmd "$ip"); read -p 'Done. Press enter...'" &
    if [[ "$UDP_SCAN" == true ]]; then
      xterm -T "nmap ${ip} UDP" -e \
        "$(build_udp_cmd "$ip"); read -p 'Done. Press enter...'" &
    fi
  done
}

# ── argument pre-scan (pick out --udp and --targets anywhere in $@) ────────────

UDP_SCAN=false
TARGETS_FILE=""
POSITIONAL=()

for arg in "$@"; do
  case "$arg" in
    --udp)         UDP_SCAN=true ;;
    --targets)     : ;;  # handled below as positional pair
    *)             POSITIONAL+=("$arg") ;;
  esac
done

# Re-parse to grab the value that follows --targets
i=0
CLEAN_ARGS=()
while [[ $i -lt $# ]]; do
  arg="${!i}"  # bash arrays are 0-indexed; use indirect
  case "$arg" in
    --udp) ;;
    --targets)
      (( i++ )) || true
      TARGETS_FILE="${!i}"
      ;;
    *) CLEAN_ARGS+=("$arg") ;;
  esac
  (( i++ )) || true
done

# ── main ──────────────────────────────────────────────────────────────────────

# ── IP source ─────────────────────────────────────────────────────────────────
if [[ -n "$TARGETS_FILE" ]]; then
  # --targets FILE was passed on the command line
  load_targets_file "$TARGETS_FILE"
elif [[ ${#CLEAN_ARGS[@]} -ge 1 ]]; then
  # First positional arg provided on command line
  IP_RANGE="${CLEAN_ARGS[0]}"
  parse_range "$IP_RANGE"
else
  # Interactive
  pick_input_source
  case "$INPUT_SOURCE" in
    targets_default)
      load_targets_file "targets.txt"
      ;;
    targets_custom)
      load_targets_file "$TARGETS_FILE"
      ;;
    *)
      read -rp "Enter IP range (e.g. 192.168.1.10-20): " IP_RANGE
      parse_range "$IP_RANGE"
      ;;
  esac
fi

# ── port range ────────────────────────────────────────────────────────────────
if [[ ${#CLEAN_ARGS[@]} -ge 2 ]]; then
  PORTS="${CLEAN_ARGS[1]}"
else
  read -rp "Enter port range [default: 1-65353]: " PORTS
  PORTS="${PORTS:-1-65353}"
fi

# ── terminal mode ─────────────────────────────────────────────────────────────
if [[ ${#CLEAN_ARGS[@]} -ge 3 ]]; then
  MODE="${CLEAN_ARGS[2]}"
else
  pick_mode
fi

# ── UDP prompt (only if not already set via --udp) ────────────────────────────
if [[ "$UDP_SCAN" == false ]]; then
  pick_udp
fi

# ── summary ───────────────────────────────────────────────────────────────────
echo ""
echo "  Hosts    : ${#IPS[@]}  (${IPS[*]})"
echo "  TCP ports: ${PORTS}"
echo "  UDP scan : ${UDP_SCAN}"
echo "  Mode     : ${MODE}"
echo "  Output   : ${OUTPUT_DIR}/<last_octet>.txt"
if [[ "$UDP_SCAN" == true ]]; then
  echo "  UDP note : top-200 UDP ports, -sU --version-intensity 0 (requires root)"
  echo "  UDP out  : ${OUTPUT_DIR}/<last_octet>_udp.txt"
fi
echo ""

setup_output_dir

case "$MODE" in
  tmux)   run_tmux ;;
  screen) run_screen ;;
  xfce4)  run_xfce4 ;;
  gnome)  run_gnome ;;
  xterm)  run_xterm ;;
  *)
    echo "ERROR: Unknown mode '${MODE}'. Use: tmux | screen | xfce4 | gnome | xterm"
    exit 1
    ;;
esac