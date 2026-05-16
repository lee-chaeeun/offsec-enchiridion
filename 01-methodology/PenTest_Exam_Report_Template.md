# OSCP Exam Report

---

## Cover Page

| Field | Details |
|---|---|
| **Candidate Name** | |
| **OSID** | |
| **Email** | |
| **Exam Date (Start)** | |
| **Exam Date (End)** | |
| **Report Submission Date** | |

---

## Table of Contents

1. [Introduction](#introduction)
2. [Exam Scope & Objectives](#exam-scope--objectives)
3. [Active Directory Set](#active-directory-set)
   - [AD Machine 1 (10 pts)](#ad-machine-1)
   - [AD Machine 2 (10 pts)](#ad-machine-2)
   - [Domain Controller (20 pts)](#domain-controller)
4. [Independent Target 1 (20 pts)](#independent-target-1)
5. [Independent Target 2 (20 pts)](#independent-target-2)
6. [Independent Target 3 (20 pts)](#independent-target-3)
7. [Appendices](#appendices)

---

## Introduction

> Briefly state the purpose of this report, the scope (OSCP exam environment), and the exam date range. Keep it professional and concise.

**Purpose:** This report documents the penetration testing process conducted during the OSCP certification exam. It includes all steps, commands issued, console output, and screenshots required to replicate the attacks performed.

**Exam Start:** `YYYY-MM-DD HH:MM UTC`  
**Exam End:** `YYYY-MM-DD HH:MM UTC`  
**Report Submitted:** `YYYY-MM-DD`

---

## Exam Scope & Objectives

- **Total Points Available:** 100
- **Passing Score:** 70
- **Point Breakdown:**
  - Active Directory Set: 40 pts (DC must be compromised for any AD points)
  - Independent Target 1: 20 pts (10 local.txt + 10 proof.txt)
  - Independent Target 2: 20 pts (10 local.txt + 10 proof.txt)
  - Independent Target 3: 20 pts (10 local.txt + 10 proof.txt)

>  All steps must be reproducible by a technically competent reader. Missing screenshots or incomplete documentation may result in zero points for that target.

---

## Active Directory Set

> The AD set must be completed **in sequence**. Partial credit is not awarded — the Domain Controller must be fully compromised to receive AD points.

### AD Machine 1

**IP Address:** `10.x.x.x`  
**Hostname:** `HOSTNAME`  
**Points:** 10  
**Status:** `[ ] Compromised`

#### Enumeration

```
# Commands used
```

*Screenshot: [Paste or embed screenshot here]*

#### Exploitation

**Vulnerability / Attack Vector:**

```
# Exploitation commands / steps
```

*Screenshot: [Paste or embed screenshot here]*

#### Proof

**local.txt value:**

```
[paste hash here]
```

*Screenshot (must show: hostname, whoami, local.txt contents):*  
![[ad-machine1-local.png]]

---

### AD Machine 2

**IP Address:** `10.x.x.x`  
**Hostname:** `HOSTNAME`  
**Points:** 10  
**Status:** `[ ] Compromised`

#### Enumeration

```
# Commands used
```

*Screenshot: [Paste or embed screenshot here]*

#### Exploitation

**Vulnerability / Attack Vector:**

```
# Exploitation commands / steps
```

*Screenshot: [Paste or embed screenshot here]*

#### Lateral Movement (if applicable)

```
# Commands used to pivot from Machine 1 to Machine 2
```

#### Proof

**local.txt value:**

```
[paste hash here]
```

*Screenshot (must show: hostname, whoami, local.txt contents):*  
![[ad-machine2-local.png]]

---

### Domain Controller

**IP Address:** `10.x.x.x`  
**Hostname:** `DC-HOSTNAME`  
**Domain:** `DOMAIN.LOCAL`  
**Points:** 20  
**Status:** `[ ] Compromised`

#### Enumeration

```
# Commands used
```

*Screenshot: [Paste or embed screenshot here]*

#### Privilege Escalation / Domain Compromise

**Attack Path:**

```
# Step-by-step commands to reach Domain Admin / SYSTEM
```

*Screenshot: [Paste or embed screenshot here]*

#### Proof

**proof.txt value:**

```
[paste hash here]
```

*Screenshot (must show: hostname, whoami/id, proof.txt contents):*  
![[dc-proof.png]]

---

## Independent Target 1

**IP Address:** `10.x.x.x`  
**Hostname/OS:** `HOSTNAME / OS`  
**Points:** 20 (10 local + 10 proof)  
**Status:** `[ ] Low Privilege` | `[ ] Privilege Escalation`

### Enumeration

#### Port Scan

```bash
nmap -sC -sV -oN target1.nmap 10.x.x.x
```

*Output:*
```
[paste scan results]
```

#### Service Enumeration

```
# Additional enumeration commands (gobuster, nikto, enum4linux, etc.)
```

### Exploitation (Low Privilege)

**Vulnerability / CVE:** 
**Attack Vector:**

```
# Exploitation steps and commands
```

*Screenshot: [Paste or embed screenshot here]*

#### local.txt

**Value:**
```
[paste hash here]
```

*Screenshot (must show: hostname, whoami/id, local.txt contents):*  
![[target1-local.png]]

### Privilege Escalation

**Vector / Technique:**

```
# Privilege escalation commands and steps
```

*Screenshot: [Paste or embed screenshot here]*

#### proof.txt

**Value:**
```
[paste hash here]
```

*Screenshot (must show: hostname, whoami/id as root/SYSTEM, proof.txt contents):*  
![[target1-proof.png]]

---

## Independent Target 2

**IP Address:** `10.x.x.x`  
**Hostname/OS:** `HOSTNAME / OS`  
**Points:** 20 (10 local + 10 proof)  
**Status:** `[ ] Low Privilege` | `[ ] Privilege Escalation`

### Enumeration

#### Port Scan

```bash
nmap -sC -sV -oN target2.nmap 10.x.x.x
```

*Output:*
```
[paste scan results]
```

#### Service Enumeration

```
# Additional enumeration commands
```

### Exploitation (Low Privilege)

**Vulnerability / CVE:**  
**Attack Vector:**

```
# Exploitation steps and commands
```

*Screenshot: [Paste or embed screenshot here]*

#### local.txt

**Value:**
```
[paste hash here]
```

*Screenshot (must show: hostname, whoami/id, local.txt contents):*  
![[target2-local.png]]

### Privilege Escalation

**Vector / Technique:**

```
# Privilege escalation commands and steps
```

*Screenshot: [Paste or embed screenshot here]*

#### proof.txt

**Value:**
```
[paste hash here]
```

*Screenshot (must show: hostname, whoami/id as root/SYSTEM, proof.txt contents):*  
![[target2-proof.png]]

---

## Independent Target 3

**IP Address:** `10.x.x.x`  
**Hostname/OS:** `HOSTNAME / OS`  
**Points:** 20 (10 local + 10 proof)  
**Status:** `[ ] Low Privilege` | `[ ] Privilege Escalation`

### Enumeration

#### Port Scan

```bash
nmap -sC -sV -oN target3.nmap 10.x.x.x
```

*Output:*
```
[paste scan results]
```

#### Service Enumeration

```
# Additional enumeration commands
```

### Exploitation (Low Privilege)

**Vulnerability / CVE:**  
**Attack Vector:**

```
# Exploitation steps and commands
```

*Screenshot: [Paste or embed screenshot here]*

#### local.txt

**Value:**
```
[paste hash here]
```

*Screenshot (must show: hostname, whoami/id, local.txt contents):*  
![[target3-local.png]]

### Privilege Escalation

**Vector / Technique:**

```
# Privilege escalation commands and steps
```

*Screenshot: [Paste or embed screenshot here]*

#### proof.txt

**Value:**
```
[paste hash here]
```

*Screenshot (must show: hostname, whoami/id as root/SYSTEM, proof.txt contents):*  
![[target3-proof.png]]

---

## Appendices

### Appendix A — Tools Used

| Tool | Purpose |
|---|---|
| `nmap` | Port scanning and service enumeration |
| `gobuster` | Directory/file brute forcing |
| `metasploit` | Exploitation framework (note: limited use allowed) |
| `mimikatz` | Credential dumping (AD) |
| | |

### Appendix B — Modified Exploits / Custom Code

> Per OffSec requirements: if you modified an existing exploit or wrote custom code, include it here. If unmodified, only provide the URL to the source.

#### Exploit: [Name]

**Source URL:** `https://...`  
**Modifications Made:**

```python
# Paste modified/custom code here
```

### Appendix C — Proof File Summary

| Target | IP | local.txt | proof.txt |
|---|---|---|---|
| AD Machine 1 | 10.x.x.x | N/A | N/A |
| AD Machine 2 | 10.x.x.x | N/A | N/A |
| Domain Controller | 10.x.x.x | N/A | `hash` |
| Independent 1 | 10.x.x.x | `hash` | `hash` |
| Independent 2 | 10.x.x.x | `hash` | `hash` |
| Independent 3 | 10.x.x.x | `hash` | `hash` |

### Appendix D — Score Tracker

| Target | Max Points | Points Earned |
|---|---|---|
| AD Machine 1 | 10 | |
| AD Machine 2 | 10 | |
| Domain Controller | 20 | |
| Independent Target 1 | 20 | |
| Independent Target 2 | 20 | |
| Independent Target 3 | 20 | |
| **Total** | **100** | |

> Pass threshold: **70 points**

---

*Report prepared by: [Your Name] | OSID: [Your OSID] | Exam Date: [Date]*
