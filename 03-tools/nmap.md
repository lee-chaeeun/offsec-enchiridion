# nmap

```text
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣤⣀⠀⢀⣼⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣷⣾⣿⣿⣷⣤⣤⣶⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⡦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣘⣻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣍⣀⣀⣀⣀⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠉⢽⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠋⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣸⣀⠀⠸⣿⣿⣿⣿⣿⣿⣿⣿⡛⣃⣤⣄⠀⠀⠀⠀⠀⣀⣀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠛⠻⣿⣿⣿⣆⠙⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⡀⠀⢠⣿⣿⣟⠛⠛⡏⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠉⣿⣿⣆⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⣼⣿⡟⠀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⠘⣿⣿⡆⢰⣿⡏⠈⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⠀⠘⣿⣿⣿⣿⠃⠀⠀⠙⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⡀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⠀⠀⠘⣿⣿⡏⠀⠀⠀⠀⠈⠻⣿⣿⣿⣿⣿⣿⣿⣿⣷⡀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⠀⠀⠀⠘⠟⠁⠀⠀⠀⠀⠀⠀⠙⣿⣿⣿⣿⣿⣿⣿⣿⣷⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⣿⣿⣿⣿⣿⣿⣿⣿⣇⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⠓⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠚⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⣠⣶⢶⣦⠀⣶⡶⠶⠆⣠⣶⣶⣶⣦⠀⠀⠀⣠⡶⢶⣦⠀⢀⣴⡶⣶⣦⢀⣶⠀⠰⣦⠀⣶⡄⠀⣶⠀⢰⡆⢰⣆⠀⣴⣶⠶⡆⣶⣶⣶⣶⣆⣶⡆⠀⢀⣦
⣸⡟⠀⠀⠀⠀⣿⣦⣤⠀⠉⠀⣿⡆⠀⠀⠀⠀⢿⣷⣤⡀⠀⣾⡏⠀⠀⠁⢸⣿⣤⣴⣿⡆⣿⡇⢠⣿⠀⣸⡇⢸⣿⠀⣿⣥⣤⠀⠈⢹⣿⠀⠀⠸⣿⣄⣼⠇
⢻⣧⡀⢸⣿⢀⣿⠉⠀⠀⠀⠀⣿⡇⠀⠀⠀⠠⣦⡈⠙⣿⡆⢿⣧⡀⢀⣠⢸⣿⠉⠀⣿⡇⢹⣧⣼⢿⣦⡿⠀⢸⣿⠀⣿⡏⠉⠀⠀⢸⣿⠀⠀⠀⢹⣿⠏⠀
⠈⠻⠿⠿⠋⠸⠟⠛⠛⠓⠀⠀⠿⠃⠀⠀⠀⠀⠙⠿⠿⠟⠁⠈⠻⠿⠿⠃⠘⠟⠀⠀⠛⠁⠀⠻⠃⠈⠛⠁⠀⠘⠟⠀⠻⠇⠀⠀⠀⠸⠿⠀⠀⠀⠺⠿⠀⠀
```


`nmap` 
- recommend to run in sudo bc many nmap scan options require access to raw sockets 
	- raw sockets allow manipulate TCP and UDP packets 
	- without raw socket access -> falls back on using standard socket API 

- sends probes 
	- TCP SYNs, connects, ACKs, FINs, UDP probes
	- service/version detection traffic (`-sV`)
	- NSE script traffic (`-sC`, `--script`)
	- host discovery probes such as ICMP, ARP, TCP pings

`nmap` leaves footprint on wire and scanned hosts
- on the wire: packets crossing the network
- on the target: logs, counters, IDS alerts, service logs, firewall logs, Windows eventing, EDR telemetry

fast loop script through multiple hosts
nmap loop with tmux using [`nmap_scan.sh`](./scripts/nmap_scan.sh)
```bash
└─$ chmod +x nmap_scan.sh
└─$ ./nmap_scan.sh 192.168.111.10-20 1-65535 tmux
```
- each scan saves to `./nmap_scan_output/<last_octet>.txt`

**Example Network**  

| Machine         | IP               |
| --------------- | ---------------- |
| Kali (attacker) | 192.168.xx.xxx   |
| Alice (target)  | 192.168.111.137  |
```bash
└─$ nmap -h                                                  
Nmap 7.98 ( https://nmap.org )
Usage: nmap [Scan Type(s)] [Options] {target specification}

TARGET SPECIFICATION:
  Can pass hostnames, IP addresses, networks, etc.
  Ex: scanme.nmap.org, microsoft.com/24, 192.168.0.1; 10.0.0-255.1-254
  -iL <inputfilename>: Input from list of hosts/networks
  -iR <num hosts>: Choose random targets
  --exclude <host1[,host2][,host3],...>: Exclude hosts/networks
  --excludefile <exclude_file>: Exclude list from file
  
HOST DISCOVERY:
  -sL: List Scan - simply list targets to scan
  -sn: Ping Scan - disable port scan
  -Pn: Treat all hosts as online -- skip host discovery
  -PS/PA/PU/PY[portlist]: TCP SYN, TCP ACK, UDP or SCTP discovery to given ports
  -PE/PP/PM: ICMP echo, timestamp, and netmask request discovery probes
  -PO[protocol list]: IP Protocol Ping
  -n/-R: Never do DNS resolution/Always resolve [default: sometimes]
  --dns-servers <serv1[,serv2],...>: Specify custom DNS servers
  --system-dns: Use OS's DNS resolver
  --traceroute: Trace hop path to each host
  
SCAN TECHNIQUES:
  -sS/sT/sA/sW/sM: TCP SYN/Connect()/ACK/Window/Maimon scans
  -sU: UDP Scan
  -sN/sF/sX: TCP Null, FIN, and Xmas scans
  --scanflags <flags>: Customize TCP scan flags
  -sI <zombie host[:probeport]>: Idle scan
  -sY/sZ: SCTP INIT/COOKIE-ECHO scans
  -sO: IP protocol scan
  -b <FTP relay host>: FTP bounce scan
  
PORT SPECIFICATION AND SCAN ORDER:
  -p <port ranges>: Only scan specified ports
    Ex: -p22; -p1-65535; -p U:53,111,137,T:21-25,80,139,8080,S:9
  --exclude-ports <port ranges>: Exclude the specified ports from scanning
  -F: Fast mode - Scan fewer ports than the default scan
  -r: Scan ports sequentially - don't randomize
  --top-ports <number>: Scan <number> most common ports
  --port-ratio <ratio>: Scan ports more common than <ratio>
  
SERVICE/VERSION DETECTION:
  -sV: Probe open ports to determine service/version info
  --version-intensity <level>: Set from 0 (light) to 9 (try all probes)
  --version-light: Limit to most likely probes (intensity 2)
  --version-all: Try every single probe (intensity 9)
  --version-trace: Show detailed version scan activity (for debugging)
  
SCRIPT SCAN:
  -sC: equivalent to --script=default
  --script=<Lua scripts>: <Lua scripts> is a comma separated list of
           directories, script-files or script-categories
  --script-args=<n1=v1,[n2=v2,...]>: provide arguments to scripts
  --script-args-file=filename: provide NSE script args in a file
  --script-trace: Show all data sent and received
  --script-updatedb: Update the script database.
  --script-help=<Lua scripts>: Show help about scripts.
           <Lua scripts> is a comma-separated list of script-files or
           script-categories.
           
OS DETECTION:
  -O: Enable OS detection
  --osscan-limit: Limit OS detection to promising targets
  --osscan-guess: Guess OS more aggressively
  
TIMING AND PERFORMANCE:
  Options which take <time> are in seconds, or append 'ms' (milliseconds),
  's' (seconds), 'm' (minutes), or 'h' (hours) to the value (e.g. 30m).
  -T<0-5>: Set timing template (higher is faster)
  --min-hostgroup/max-hostgroup <size>: Parallel host scan group sizes
  --min-parallelism/max-parallelism <numprobes>: Probe parallelization
  --min-rtt-timeout/max-rtt-timeout/initial-rtt-timeout <time>: Specifies
      probe round trip time.
  --max-retries <tries>: Caps number of port scan probe retransmissions.
  --host-timeout <time>: Give up on target after this long
  --scan-delay/--max-scan-delay <time>: Adjust delay between probes
  --min-rate <number>: Send packets no slower than <number> per second
  --max-rate <number>: Send packets no faster than <number> per second
  
FIREWALL/IDS EVASION AND SPOOFING:
  -f; --mtu <val>: fragment packets (optionally w/given MTU)
  -D <decoy1,decoy2[,ME],...>: Cloak a scan with decoys
  -S <IP_Address>: Spoof source address
  -e <iface>: Use specified interface
  -g/--source-port <portnum>: Use given port number
  --proxies <url1,[url2],...>: Relay connections through HTTP/SOCKS4 proxies
  --data <hex string>: Append a custom payload to sent packets
  --data-string <string>: Append a custom ASCII string to sent packets
  --data-length <num>: Append random data to sent packets
  --ip-options <options>: Send packets with specified ip options
  --ttl <val>: Set IP time-to-live field
  --spoof-mac <mac address/prefix/vendor name>: Spoof your MAC address
  --badsum: Send packets with a bogus TCP/UDP/SCTP checksum
  
OUTPUT:
  -oN/-oX/-oS/-oG <file>: Output scan in normal, XML, s|<rIpt kIddi3,
     and Grepable format, respectively, to the given filename.
  -oA <basename>: Output in the three major formats at once
  -v: Increase verbosity level (use -vv or more for greater effect)
  -d: Increase debugging level (use -dd or more for greater effect)
  --reason: Display the reason a port is in a particular state
  --open: Only show open (or possibly open) ports
  --packet-trace: Show all packets sent and received
  --iflist: Print host interfaces and routes (for debugging)
  --append-output: Append to rather than clobber specified output files
  --resume <filename>: Resume an aborted scan
  --noninteractive: Disable runtime interactions via keyboard
  --stylesheet <path/URL>: XSL stylesheet to transform XML output to HTML
  --webxml: Reference stylesheet from Nmap.Org for more portable XML
  --no-stylesheet: Prevent associating of XSL stylesheet w/XML output
  
MISC:
  -6: Enable IPv6 scanning
  -A: Enable OS detection, version detection, script scanning, and traceroute
  --datadir <dirname>: Specify custom Nmap data file location
  --send-eth/--send-ip: Send using raw ethernet frames or IP packets
  --privileged: Assume that the user is fully privileged
  --unprivileged: Assume the user lacks raw socket privileges
  -V: Print version number
  -h: Print this help summary page.
  
EXAMPLES:
  nmap -v -A scanme.nmap.org
  nmap -v -sn 192.168.0.0/16 10.0.0.0/8
  nmap -v -iR 10000 -Pn -p 80
SEE THE MAN PAGE (https://nmap.org/book/man.html) FOR MORE OPTIONS AND EXAMPLES
```


## TCP PORT SCAN

full TCP port + service/version + default script scan 
```bash
└─$ sudo nmap -p 1-65535 -sC -sV 192.168.111.137 -Pn  
```
- `-sC` = default NSE scripts
- `-sV` = service/version detection
- `-p-`: full port scan
- `-p 1-65535`: full port scan

save `nmap` terminal output to file 
```bash
└─$ sudo nmap -sC -sV -oN hostname/nmap.txt 192.168.111.137  
```
- -`oN` : create output file - contain scan results  
- `-oA` = save `.nmap`, `.xml`, and `.gnmap`

os detection
```bash
sudo nmap -O target_ip
```

aggressive scan to combine all 
- OS detection
- version detection
- default scripts
- traceroute
```bash
sudo nmap -A target_ip
```

### NMAP SCRIPTING ENGINE (NSE) scripts 
-  `--script`: use to launch user-created scripts to automate scanning tasks
-  `/usr/share/nmap/scripts`

find script if lost 
`--script-help` : description of script & url 
```bash
└─$ nmap --script-help http-headers          
Starting Nmap 7.95 ( https://nmap.org ) at 2025-01-28 23:02 CET

http-headers
Categories: discovery safe
https://nmap.org/nsedoc/scripts/http-headers.html
  Performs a HEAD request for the root folder ("/") of a web server and displays the HTTP headers returned.
```

SMTP enumeration 
```bash
└─$ sudo nmap -p 25 --script smtp-enum-users 192.168.111.137
```

IMAP enumeration
```bash
sudo nmap --script imap-brute -p 143 192.168.111.137      
```

HTTP enumeration
```bash
nmap -p80 --script=http-enum target_ip
```

HTTP multiple scripts
```bash
nmap -p 80,443 --script http-enum,http-title,http-headers,http-methods target_ip
```
- `http-headers`: sends an HTTP request (typically `HEAD /`) and displays the response headers returned by the server 

SMB enumeration
```bash
nmap -p 445 --script smb-enum-shares,smb-enum-users,smb-os-discovery target_ip
```

SMB vulnerability checks
```bash
nmap -p 445 --script smb-vuln* target_ip
```

SSH enumeration
```bash
nmap -p 22 --script ssh-auth-methods,ssh-hostkey target_ip
```

DNS enumeration
```bash
nmap --script dns-brute domain.com  
nmap --script dns-zone-transfer domain.com
```

MySQL enumeration
```bash
nmap -p 3306 --script mysql-info,mysql-enum target_ip
```

TCP + UDP combined scanning 
```bash
sudo nmap -sS -sU -p T:80,443,445,U:53,161 target_ip
```

## UDP SCANNING

useful for DNS, SNMP, NTP, TFTP, IKE, etc.

```bash
kali@kali:~$ sudo nmap -sU 192.168.111.137

Starting Nmap 7.70 ( https://nmap.org ) at 2019-03-04 11:46 EST
Nmap scan report for 192.168.111.137
Host is up (0.11s latency).
Not shown: 977 closed udp ports (port-unreach)
PORT      STATE         SERVICE
123/udp   open          ntp
389/udp   open          ldap
```
- `-sU`: UDP scan 

```bash
kali@kali:~$ sudo nmap -sU -sS 192.168.111.137

Starting Nmap 7.92 ( https://nmap.org ) at 2022-03-09 08:16 EST
Nmap scan report for 192.168.111.137
Host is up (0.10s latency).
Not shown: 989 closed tcp ports (reset), 977 closed udp ports (port-unreach)
PORT      STATE         SERVICE
53/tcp    open          domain
88/tcp    open          kerberos-sec
...
3269/tcp  open          globalcatLDAPssl
53/udp    open          domain
123/udp   open          ntp
```
- combine `-sU` & `-sS` for complete scan  


## Timing options

faster local/ lab scan
```bash
sudo nmap -T4 --min-rate 1000 target_ip
```

slow/safer scan
```bash
nmap -T2 target_ip
```

limit time on scan of slow host
```bash
nmap --host-timeout 30m target_ip
```


### proxychains bash one-liners for quick port scan

from a targets file (one IP per line) check port of target hosts 
```bash
kali@kali:~$ cat targets.txt
10.10.111.13  
10.10.111.14  
10.10.111.15
```

(e.g.  VNC 5900)
```bash
kali@kali:~$ while read -r h; do proxychains -q timeout 4 nc -z -w 3 "$h" 5900 >/dev/null 2>&1 && echo "$h:5900 open"; done < targets.txt

10.10.111.15:5900 open
```
- `proxychains -q`: forces connection through SOCKS proxy
- `-q`: quiet mode to decrease noisy output with proxychains
- `timeout 4`: kills cmd if takes longer than 4 seconds
- `nc -z -w 3 "$h" 5900`: port check 
- `>/dev/null 2>&1`: hide normal outputs and errors
- `&& echo "$h:5900 open"`: only output success 

sweep a subnet (/24) for specific port  (e.g.  VNC 5900)
```bash
kali@kali:~$ for i in {1..254}; do h=10.10.172.$i; proxychains -q timeout 4 nc -z -w 3 "$h" 5900 >/dev/null 2>&1 && echo "$h:5900 open"; done
```

3) Check several common ports (edit the list as you like)
```bash
while read -r h; do for p in 21 22 80 443 445 3389 5900 8080; do proxychains -q timeout 3 nc -z -w 2 "$h" "$p" >/dev/null 2>&1 && echo "$h:$p open"; done; done < targets.txt
```


## NETWORK SWEEPING

- broad scan to deal with many hosts and/or conserve network traffic

Attack vector
1. broad sweep to find live hosts in network! 
2. specific scans against hosts of interest

- `sn` : network sweep 
- `oG`: greppable output into text! 

scan network for live hosts
```bash
kali@kali:~$ nmap -v -sn 192.168.111.1-253 -oG ping-sweep.txt

Starting Nmap 7.92 ( https://nmap.org ) at 2022-03-10 03:21 EST
Initiating Ping Scan at 03:21
...
Read data files from: /usr/bin/../share/nmap
Nmap done: 254 IP addresses (13 hosts up) scanned in 3.74 seconds
...

kali@kali:~$ grep Up ping-sweep.txt | cut -d " " -f 2
192.168.111.6
192.168.111.8
192.168.111.9
...
```
- `cut`: rm lines based on delimiters
- `-d " "`: sets delimiter to space " "
- `-f 2`: extract 2nd field from each line of input based on delimiter

scan network for live hosts of specific port (e.g. 80)
```bash
kali@kali:~$ nmap -p 80 192.168.111.1-253 -oG web-sweep.txt

Starting Nmap 7.92 ( https://nmap.org ) at 2022-03-10 03:50 EST
Nmap scan report for 192.168.50.6
Host is up (0.11s latency).

PORT   STATE SERVICE
80/tcp open  http

Nmap scan report for 192.168.50.8
Host is up (0.11s latency).

PORT   STATE  SERVICE
80/tcp closed http
...

kali@kali:~$ grep open web-sweep.txt | cut -d" " -f2
192.168.111.137
192.168.111.138
192.168.111.139
```

scan network for live hosts with top ports 
```bash 
kali@kali:~$ nmap -sT -A --top-ports=20 192.168.111.1-253 -oG top-port-sweep.txt

Starting Nmap 7.92 ( https://nmap.org ) at 2022-03-10 04:04 EST
Nmap scan report for 192.168.111.137
Host is up (0.12s latency).

PORT     STATE  SERVICE       VERSION
21/tcp   closed ftp
22/tcp   open   ssh           OpenSSH 8.2p1 Ubuntu 4ubuntu0.3 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey:
|   3072 <REDACTED_SSH_HOSTKEY> (RSA)
|   256 <REDACTED_SSH_HOSTKEY> (ECDSA)
|_  256 <REDACTED_SSH_HOSTKEY> (ED25519)
23/tcp   closed telnet
25/tcp   closed smtp
53/tcp   closed domain
80/tcp   open   http          Apache httpd 2.4.41 ((Ubuntu))
|_http-server-header: Apache/2.4.41 (Ubuntu)
|_http-title: Under Construction
110/tcp  closed pop3
111/tcp  closed rpcbind
...
```
- `--top-ports` : using` /usr/share/nmap/nmap-services` file 
		- contains = {port number,  protocol, port frequency} 
- `-A`: traceroute, OS ver detection, script scanning 


## OS FINGERPRINTING

- `-O`
	- nmap figures out OS based on the fact that each OS uses differernt implementations of TCP/IP stack. 
	- matches traffic from target machine and to fingerprints

- `--osscan-guess`
	- by default prints only accurate results
	- but guess forces nmap to print all results even if they are not fully accurate 

```bash
kali@kali:~$ sudo nmap -O 192.168.111.137 --osscan-guess

Starting Nmap 7.94 ( https://nmap.org ) at 2026-04-19 21:15 +0200  
Nmap scan report for 192.168.111.137  
Host is up (0.10s latency).  
Not shown: 996 closed tcp ports (reset)  
PORT STATE SERVICE  
53/tcp open domain  
88/tcp open kerberos-sec  
135/tcp open msrpc  
139/tcp open netbios-ssn  
  
Device type: general purpose  
Running (JUST GUESSING): Microsoft Windows 2008|2012|2016|7|Vista (88%)  
OS CPE: cpe:/o:microsoft:windows_server_2008 cpe:/o:microsoft:windows_server_2012 cpe:/o:microsoft:windows_server_2016 cpe:/o:microsoft:windows_7 cpe:/o:microsoft:windows_vista  
Aggressive OS guesses: Microsoft Windows Server 2012 R2 (88%), Microsoft Windows 7 or Windows Server 2008 R2 (87%), Microsoft Windows Server 2016 (86%)  
No exact OS matches for host (test conditions non-ideal).  
  
Network Distance: 1 hop  
  
OS detection performed. Please report any incorrect results at https://nmap.org/submit/ .  
Nmap done: 1 IP address (1 host up) scanned in 24.63 seconds
```

aggressive mode example 
```bash
kali@kali:~$ nmap -sT -A 192.168.111.13

Nmap scan report for 192.168.111.137  
Host is up (0.11s latency).  
Not shown: 989 closed tcp ports (conn-refused)  
PORT STATE SERVICE VERSION  
53/tcp open domain Simple DNS Plus  
88/tcp open kerberos-sec Microsoft Windows Kerberos  
135/tcp open msrpc Microsoft Windows RPC  
139/tcp open netbios-ssn Microsoft Windows netbios-ssn  
389/tcp open ldap Microsoft Windows Active Directory LDAP  
445/tcp open microsoft-ds?  
464/tcp open kpasswd5?  
593/tcp open ncacn_http Microsoft Windows RPC over HTTP 1.0  
636/tcp open ssl/ldap Microsoft Windows Active Directory LDAP (Domain: example.local)  
3268/tcp open ldap Microsoft Windows Active Directory LDAP  
3269/tcp open ssl/ldap Microsoft Windows Active Directory LDAP  
  
Host script results:  
| smb2-security-mode:  
| 3:1:1:  
|_ Message signing enabled and required  
| smb2-time:  
| date: 2026-04-19T19:18:37  
|_ start_date: N/A  
|_clock-skew: 2s  
  
Service Info: Host: DC01; OS: Windows; CPE: cpe:/o:microsoft:windows  
  
Warning: OSScan results may be unreliable because we could not find at least 1 open and 1 closed port  
Device type: general purpose  
Running: Microsoft Windows  
OS CPE: cpe:/o:microsoft:windows  
OS details: Microsoft Windows Server 2012 R2 - 2016  
Network Distance: 1 hop  
TRACEROUTE (using port 135/tcp)  
HOP RTT ADDRESS  
1 110.23 ms 192.168.111.137  
  
Nmap done: 1 IP address (1 host up) scanned in 78.41 seconds
```


## STEALTH/ SYN SCANNING 

in real-life pentest scenarios, it is good to be aware of footprints being left behind

- `-sT` is usually noisier than `-sS`.
- `-sC` and `-sV` are noisier than a basic port scan.
- UDP scans may stand out because of ICMP unreachable responses.
- Windows DCs, web apps, and monitored environments often leave more evidence than simple lab VMs.
- 
- `-sT` : TCP 
	- default when unprivileged / non-root
	- does not requires raw socket privileges from user
	- uses the OS networking stack to complete a full TCP connection
		- likely to generate application/service logs because the full connection is established

- `sS`: SYN scan / half-open scan
	- requires raw socket privileges from user
	- sends SYN packets to various ports w/o complete TCP handshake
		1. Kali sends `SYN` to Alice 
		2. If TCP port open, Alice sends `SYN-ACK`to kali   
		3. Kali nmap sends `RST` instead of completing handshake
	- info is not passed to Application layer on Alice -> does not appear in application logs
	- fast & fewer packets sent/receive
	- still detectable on the wire and may still be logged by firewalls, IDS/IPS, EDR, or host monitoring

- Open port -> target replies with `SYN-ACK`  
- Closed port -> target replies with `RST`  
- Filtered port -> no reply or ICMP filtering-related response

```bash
kali@kali:~$ sudo nmap -sS 192.168.111.137
Starting Nmap 7.92 ( https://nmap.org ) at 2022-03-09 06:31 EST
Nmap scan report for 192.168.111.137
Host is up (0.11s latency).
Not shown: 989 closed tcp ports (reset)
PORT     STATE SERVICE
53/tcp   open  domain
88/tcp   open  kerberos-sec
135/tcp  open  msrpc
139/tcp  open  netbios-ssn
```

Noise comparison chart

| Scan / Situation                          | Relative Noise    | Why it is Noisier                                                                         | Notes                                                                                              |
| ----------------------------------------- | ----------------- | ----------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| Basic TCP SYN scan (`-sS`)                | Lower             | Sends SYN probes without completing full TCP connections in the same way as connect scans | Often quieter than `-sT`, but still visible on the wire and potentially logged                     |
| TCP connect scan (`-sT`)                  | Higher            | Completes full TCP connections via the OS networking stack                                | More likely to generate application/service logs                                                   |
| Default script scan (`-sC`)               | Higher            | Runs NSE scripts that actively interact with services                                     | Can trigger extra logging, unusual requests, or even account lockouts depending on script behavior |
| Version detection (`-sV`)                 | Higher            | Sends protocol-specific probes to identify service versions                               | More informative, but more obvious than a basic port-only scan                                     |
| Basic port scan only                      | Lower             | Primarily checks open/closed ports without deeper interaction                             | Good first step before adding scripts or version detection                                         |
| UDP scan (`-sU`)                          | Medium to High    | Can trigger ICMP unreachable responses and unusual UDP traffic patterns                   | Often slower, noisier in some environments, and less reliable to interpret                         |
| Scanning a Windows DC                     | Higher visibility | Domain controllers are often heavily monitored and run many sensitive services            | Expect more logging potential, especially around Kerberos, LDAP, SMB, RPC                          |
| Scanning a web app                        | Medium to High    | Requests may appear in web server, proxy, WAF, or app logs                                | Directory brute force, parameter fuzzing, and auth attempts are especially noticeable              |
| Scanning a monitored enterprise-like host | High              | IDS/IPS, EDR, firewall, and central logging may all observe activity                      | Small actions may create multiple telemetry points                                                 |
| Scanning a simple lab VM                  | Lower visibility  | Usually fewer defensive controls and less centralized monitoring                          | Still leaves a footprint, just often less recorded                                                 |

## troubleshooting

### kali/ linux 

use `iptables` as diagnostic tool

```bash
# insert rule matching traffic from target into INPUT
└─$ sudo iptables -I INPUT 1 -s 192.168.111.137 -j ACCEPT 

# insert rule matching traffic to target into OUTPUT
└─$ sudo iptables -I OUTPUT 1 -d 192.168.111.137 -j ACCEPT

# reset packet and byte counters to zero
└─$ sudo iptables -Z
```

confirm changes made: 
- packets are leaving Kali
- replies are coming back
- how much traffic matched those rules
- `-vn`: verbose and numeric format (does not try to resolve name)

```bash
└─$  sudo iptables -vn -L
Chain INPUT (policy ACCEPT 1270 packets, 115K bytes)
 pkts bytes target     prot opt in     out     source               destination
 1196 47972 ACCEPT     all  --  *      *       192.168.111.137      0.0.0.0/0

Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination

Chain OUTPUT (policy ACCEPT 1264 packets, 143K bytes)
 pkts bytes target     prot opt in     out     source               destination
 1218 72640 ACCEPT     all  --  *      *       0.0.0.0/0            192.168.111.137
```
- default 1000 port scan --> gen 72 KB traffic in OUTPUT chain 

if everything is working -> then failed connection is not blocked by kali

## Port Scanning on Windows

`Test-NetConnection `checks 
- if IP responds to ICMP 
- if TCP port on target open 


checking whether TCP/445 is reachable from one Windows host to another
e.g. lateral movement enumeration scenario (Bob 138 -> Alice 137)
```powershell
PS C:\Users\bob> Test-NetConnection -Port 445 192.168.111.137

ComputerName     : 192.168.111.137
RemoteAddress    : 192.168.111.137
RemotePort       : 445
InterfaceAlias   : Ethernet0
SourceAddress    : 192.168.111.138
TcpTestSucceeded : True

PS C:\Users\bob> 1..1024 | ForEach-Object {  
try {  
$c = New-Object Net.Sockets.TcpClient  
$c.Connect("192.168.111.137", $_)  
"TCP port $_ is open"  
$c.Close()  
} catch {}  
}
```
- scan 1-1024 performs TCP connection against target IP on port
- if success -> opens TCP port log 

---
<sub>source of <a href="https://emojicombos.com/rick-and-morty-ascii-art"> rick ascii art </a></sub>

