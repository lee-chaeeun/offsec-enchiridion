# offsec-enchiridion

Organised for fast lookup during the exam and labs. 

 Don't Panic. Nobody exists on purpose, nobody belongs anywhere, everybody's gonna get pwned...and most importantly, I have my towel.

# Repository Structure 
```bash
offsec-enchiridion/
├── 00-index.md
├── 01-methodology
│   ├── OSCP_Exam_Report_Template.md
│   └── initial-checklist.md
├── 02-cheatsheets
│   ├── cmd-cheatsheet.md
│   └── port_numbers.md
├── 03-tools
│   ├── bloodhound.md
│   ├── brute-force.md
│   ├── burp.md
│   ├── crackmapexec.md
│   ├── evil-winrm.md
│   ├── gobuster.md
│   ├── hashcat_johntheripper.md
│   ├── impacket.md
│   ├── ligolo-ng.md
│   ├── metasploit.md
│   ├── mimikatz.md
│   ├── netexec.md
│   ├── nmap.md
│   ├── powerview.md
│   ├── scripts
│   │   ├── adduser.c
│   │   ├── adduser.exe
│   │   ├── chmod_calc.sh
│   │   ├── cme_bloop.sh
│   │   ├── dll_injection.cpp
│   │   ├── get-ldapobjectproperties.ps1
│   │   ├── ldap_search_helper.ps1
│   │   ├── nmap_scan.sh
│   │   └── nxc_bloop.sh
│   └── tmux.md
├── 04-exploitation
│   ├── databases
│   │   └── SQL-injection.md
│   ├── email
│   │   └── phishing.md
│   ├── reverse-shell.md
│   └── web
│       └── web-app-attack.md
├── 05-privesc-local
│   ├── linux
│   │   └── linux-privesc-overview.md
│   └── windows
│       ├── dll-hijacking.md
│       ├── scheduled-tasks.md
│       ├── token-impersonation.md
│       └── windows-privesc-overview.md
├── 06-active-directory
│   ├── ad-enumeration.md
│   ├── domain-privesc.md
│   ├── kerberos-attacks.md
│   └── lateral-movement.md
├── 07-post-exploitation
│   └── pivoting.md
├── 08-cloud
│   └── aws-overview.md
├── LICENSE
├── README.md
└── figures

```


## Repository Index  
  
### Root  
  
- [00-index.md](./00-index.md)  
- [README.md](./README.md)  
- [LICENSE](./LICENSE)  
  
### 01 Methodology  
  
- [OSCP Exam Report Template](./01-methodology/OSCP_Exam_Report_Template.md)  
- [Initial Checklist](./01-methodology/initial-checklist.md)  
  
### 02 Cheatsheets  
  
- [CMD Cheatsheet](./02-cheatsheets/cmd-cheatsheet.md)  
- [Port Numbers](./02-cheatsheets/port_numbers.md)  
  
### 03 Tools  
  
- [BloodHound](./03-tools/bloodhound.md)  
- [Brute Force / Password Attacks](./03-tools/brute-force.md)  
- [Burp Suite](./03-tools/burp.md)  
- [CrackMapExec](./03-tools/crackmapexec.md)  
- [Evil-WinRM](./03-tools/evil-winrm.md)  
- [Gobuster](./03-tools/gobuster.md)  
- [Hashcat / John the Ripper](./03-tools/hashcat_johntheripper.md)  
- [Impacket](./03-tools/impacket.md)  
- [Ligolo-ng](./03-tools/ligolo-ng.md)  
- [Metasploit](./03-tools/metasploit.md)  
- [Mimikatz](./03-tools/mimikatz.md)  
- [NetExec](./03-tools/netexec.md)  
- [Nmap](./03-tools/nmap.md)  
- [PowerView](./03-tools/powerview.md)  
- [Tmux](./03-tools/tmux.md)  
  
#### 03 Tools / Scripts  
  
- [adduser.c](./03-tools/scripts/adduser.c)  
- [adduser.exe](./03-tools/scripts/adduser.exe)  
- [chmod_calc.sh](./03-tools/scripts/chmod_calc.sh)  
- [cme_bloop.sh](./03-tools/scripts/cme_bloop.sh)  
- [dll_injection.cpp](./03-tools/scripts/dll_injection.cpp)  
- [get-ldapobjectproperties.ps1](./03-tools/scripts/get-ldapobjectproperties.ps1)  
- [ldap_search_helper.ps1](./03-tools/scripts/ldap_search_helper.ps1)  
- [nmap_scan.sh](./03-tools/scripts/nmap_scan.sh)  
- [nxc_bloop.sh](./03-tools/scripts/nxc_bloop.sh)  
  
### 04 Exploitation  
  
- [Reverse Shells](./04-exploitation/reverse-shell.md)  
  
#### 04 Exploitation / Databases  
  
- [SQL Injection](./04-exploitation/databases/SQL-injection.md)  
  
#### 04 Exploitation / Email  
  
- [Phishing for Access](./04-exploitation/email/phishing.md)  
  
#### 04 Exploitation / Web  
  
- [Web Application Attacks](./04-exploitation/web/web-app-attack.md)  
  
### 05 Privilege Escalation - Local  
  
#### Linux  
  
- [Linux Privilege Escalation Overview](./05-privesc-local/linux/linux-privesc-overview.md)  
  
#### Windows  
  
- [DLL Hijacking](./05-privesc-local/windows/dll-hijacking.md)  
- [Scheduled Tasks](./05-privesc-local/windows/scheduled-tasks.md)  
- [Token Impersonation](./05-privesc-local/windows/token-impersonation.md)  
- [Windows Privilege Escalation Overview](./05-privesc-local/windows/windows-privesc-overview.md)  
  
### 06 Active Directory  
  
- [AD Enumeration](./06-active-directory/ad-enumeration.md)  
- [Domain Privilege Escalation](./06-active-directory/domain-privesc.md)  
- [Kerberos Attacks](./06-active-directory/kerberos-attacks.md)  
- [Lateral Movement](./06-active-directory/lateral-movement.md)  
  
### 07 Post-Exploitation  
  
- [Pivoting](./07-post-exploitation/pivoting.md)


---


_For personal study use only. All techniques documented here are intended for use in authorised environments. Always obtain proper written permission before testing any system._


----

### License

This repository is licensed under the MIT License. See [LICENSE](./LICENSE).