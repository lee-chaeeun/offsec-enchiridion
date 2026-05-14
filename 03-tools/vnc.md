# VNC

VNC = remote desktop protocol 
- commonly exposed on TCP ports `5900`, `5901`, `5902`, etc. 
- During enumeration check 
	- whether VNC is exposed
	- whether authentication is required
	- whether recovered credentials or decrypted VNC passwords allow access.#
## Quick service detection

```bash
nmap -sV -sC -p 5900-5905 target_ip
```

Version/banner check:
```
nc -nv target_ip 5900
```

## Connect with vncviewer

Basic connection:
```
vncviewer target_ip
```

Connect to a specific VNC port:
```
vncviewer target_ip::5901
```

Connect using display syntax:
```
vncviewer target_ip:1
```

Notes:

- `target_ip:1` usually maps to TCP `5901`
- `target_ip:2` usually maps to TCP `5902`
- `target_ip::5901` connects directly to TCP port `5901`

## Check credentials with NetExec

```
nxc vnc target_ip -u username -p 'password'
```

If you have multiple candidate passwords:
```
nxc vnc target_ip -u username -P passwords.txt
```

If you have a username list and one password:
```
nxc vnc target_ip -U usernames.txt -p 'password'
```

## Anonymous or no-auth VNC

Some VNC services may allow access without credentials.

Check with Nmap:
```
nmap --script vnc-info,vnc-title -p 5900-5905 target_ip
```

Try connecting manually:
```
vncviewer target_ip
```

If no password is requested, inspect the session carefully and document the access path.

## Recovered VNC passwords

VNC passwords are sometimes stored in an obfuscated format. 
If a VNC password value is recovered from a config file, registry key, or backup, try decrypting it with `vncpasswd.py`.

Related helper script
use https://github.com/trinitronx/vncpasswd.py

```bash
┌──(kali㉿kali)-[~/oscp/exploits/scripts/vncpasswd.py]
└─$ python2 ./vncpasswd.py --help
usage: vncpasswd.py [-h] [-d] [-e] [-H] [-R] [-o] [-f FILENAME] [-t] [passwd]

Encrypt or Decrypt a VNC password

positional arguments:
  passwd                A password to encrypt

optional arguments:
  -h, --help            show this help message and exit
  -d, --decrypt         Decrypt an obfuscated password.
  -e, --encrypt         Encrypt a plaintext password. (default mode)
  -H, --hex             Assume input is in hex.
  -R, --registry        Input or Output to the windows registry.
  -o, --stdout          Input or Output only the resulting value to STDOUT.
                        Always output ciphertext in hexidecimal, and plaintext
                        in ASCII / UTF-8. A newline is appended to the value.
                        Useful for scripting.
  -f FILENAME, --file FILENAME
                        Input or Output to a specified file.
  -t, --test            Run the unit tests for this program.
```

```bash
└─$ python2 ./vncpasswd.py --decrypt --hex REDACTED_HEX

WARN: Ciphertext length was not divisible by 8 (hex/16).
Length: 9
Hex Length: 18
Decrypted Bin Pass= 'password_decrypted'
Decrypted Hex Pass= 'decrypted_hex_passwd'
```

Decrypt a recovered hex value:
```
python2 ./vncpasswd.py --decrypt --hex vnc_hex
```

Cleaner output:
```
python2 ./vncpasswd.py --decrypt --hex vnc_hex --stdout
```

Then test the decrypted password:
```
vncviewer target_ip
```
or:
```
nxc vnc target_ip -u username -p 'password'
```

look for
- VNC service exposed on `5900+`
- no-auth or weak-auth VNC
- reusable credentials
- VNC passwords in config files or registry values
- screenshots, desktop sessions, terminals, or open files
- access as a privileged desktop user
- internal tools, saved sessions, or credentials visible in the GUI

## Useful follow-up checks

After connecting, check the current user context from any available shell or terminal:

Windows:
```
whoami
whoami /priv
whoami /groups
```

Linux:
```
whoami
id
hostname
```

Check whether the VNC session gives access to sensitive files, terminals, scripts, or admin tools.

Common mistakes
- assuming VNC always uses port `5900`
- confusing display syntax `target_ip:1` with raw port syntax `target_ip::5901`
- testing only one port instead of `5900-5905`
- ignoring VNC because NetExec does not find valid credentials
- forgetting to try manually with `vncviewer`
- publishing recovered VNC password hashes or decrypted passwords in notes
- assuming GUI access equals full privilege escalation without checking user context