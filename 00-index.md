
```
# OSCP Index — Situation Navigator

## I have a target, where do I start?
- Unknown services → [[nmap]]
- Known port, what runs here? → [[ports]]

## I found a web service
- General recon → [[web]]
  - Found a login page → [[auth-bypass]] · [[password-attacks]]
  - Found file upload → [[file-upload]]
  - Found SQLi → [[sqli]] → got creds → [[password-attacks]]
  - Found LFI → [[lfi-rfi]]
    - LFI → log poisoning → shell → [[reverse-shells]]
  - Got a shell → [[ttys]] → [[situational-awareness]]

## I'm on a Linux box
- Situational awareness → [[situational-awareness]]
- Looking for privesc → [[linux-privesc-checklist]]
  - SUID/capabilities → [[capabilities-suid]]
  - Cron jobs → [[cron-services-timers]]
  - Kernel exploit → [[kernel]]

## I'm on a Windows box
- Situational awareness → [[situational-awareness]]
- Looking for privesc → [[windows-privesc-checklist]]
  - DLL hijacking → [[dll-hijacking]]
  - Unquoted service path → [[unquoted-service-paths]]
  - AlwaysInstallElevated → [[alwaysinstall-elevated]]

## I'm in an AD environment
- Start here → [[ad-enumeration]] → [[bloodhound]]
  - Got credentials → [[kerberos-attacks]]
  - Got a hash → [[hashes-tickets]] · [[impacket]]
  - Need to move laterally → [[lateral-movement]] · [[evil-winrm]]
  - Path to DC → [[domain-privesc]]

## I need to transfer files
→ [[file-transfer]] · [[encoding-transfer]]

## I need to pivot / tunnel
→ [[pivoting-port-forwarding]]
  - Tool: [[ligolo]] · [[chisel]] · [[ssh-tunneling]]
```

