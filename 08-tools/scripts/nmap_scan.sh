#!/usr/bin/env bash
# nmap_scan.sh — scan an IP range, one terminal window/tab per host
# Usage: ./nmap_scan.sh [ip_range] [port_range] [mode]
# Example: ./nmap_scan.sh 192.168.1.10-20 1-65353 tmux
# If no args given, runs interactively.

set -e

# ── helpers ────────────────────────────────────────────────────────────────────

usage() {
  echo "Usage: $0 [ip_range] [port_range] [mode]"
  echo ""
  echo "  ip_range   e.g. 192.168.1.10-20"
  echo "  port_range e.g. 1-65353  (default: 1-65353)"
  echo "  mode       gnome | xfce4 | xterm | tmux | screen  (default: tmux)"
  echo ""
  echo "Examples:"
  echo "  $0 192.168.111.137-145"
  echo "  $0 192.168.111.137-145 1-1024 xfce4"
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

# ── modes ─────────────────────────────────────────────────────────────────────

run_tmux() {
  echo "[*] Launching tmux session 'nmap_scan' with ${#IPS[@]} windows..."
  local first="${IPS[0]}"
  tmux new-session -d -s nmap_scan -n "$first" \
    "sudo nmap -p ${PORTS} -sC -sV ${first} -Pn; read -p 'Done. Press enter...'"
  for ip in "${IPS[@]:1}"; do
    tmux new-window -t nmap_scan -n "$ip" \
      "sudo nmap -p ${PORTS} -sC -sV ${ip} -Pn; read -p 'Done. Press enter...'"
  done
  echo "[*] Attaching — use Ctrl+b <number> to switch windows, Ctrl+b d to detach."
  tmux attach-session -t nmap_scan
}

run_screen() {
  echo "[*] Launching GNU screen session 'nmap_scan' with ${#IPS[@]} windows..."
  local first="${IPS[0]}"
  screen -dmS nmap_scan -t "$first" bash -c \
    "sudo nmap -p ${PORTS} -sC -sV ${first} -Pn; read -p 'Done. Press enter...'"
  for ip in "${IPS[@]:1}"; do
    screen -S nmap_scan -X screen -t "$ip" bash -c \
      "sudo nmap -p ${PORTS} -sC -sV ${ip} -Pn; read -p 'Done. Press enter...'"
  done
  echo "[*] Attaching — use Ctrl+a <number> to switch windows, Ctrl+a d to detach."
  screen -r nmap_scan
}

run_xfce4() {
  echo "[*] Opening ${#IPS[@]} xfce4-terminal tabs..."
  local cmd="xfce4-terminal"
  for ip in "${IPS[@]}"; do
    cmd+=" --tab -T 'nmap ${ip}' -e \"bash -c 'sudo nmap -p ${PORTS} -sC -sV ${ip} -Pn; read -p Done.\\\ Press\\\ enter...'\""
  done
  eval "$cmd" &
}

run_gnome() {
  echo "[*] Opening ${#IPS[@]} GNOME Terminal tabs..."
  local cmd="gnome-terminal"
  for ip in "${IPS[@]}"; do
    cmd+=" --tab -- bash -c \"sudo nmap -p ${PORTS} -sC -sV ${ip} -Pn; exec bash\""
  done
  eval "$cmd" &
}

run_xterm() {
  echo "[*] Opening ${#IPS[@]} xterm windows..."
  for ip in "${IPS[@]}"; do
    xterm -T "nmap ${ip}" -e \
      "sudo nmap -p ${PORTS} -sC -sV ${ip} -Pn; read -p 'Done. Press enter...'" &
  done
}

# ── main ──────────────────────────────────────────────────────────────────────

# Parse arguments or prompt interactively
if [[ $# -ge 1 ]]; then
  IP_RANGE="$1"
else
  read -rp "Enter IP range (e.g. 192.168.1.10-20): " IP_RANGE
fi

if [[ $# -ge 2 ]]; then
  PORTS="$2"
else
  read -rp "Enter port range [default: 1-65353]: " PORTS
  PORTS="${PORTS:-1-65353}"
fi

if [[ $# -ge 3 ]]; then
  MODE="$3"
else
  pick_mode
fi

parse_range "$IP_RANGE"

echo ""
echo "  IP range : ${IP_RANGE} (${#IPS[@]} hosts)"
echo "  Ports    : ${PORTS}"
echo "  Mode     : ${MODE}"
echo ""

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
