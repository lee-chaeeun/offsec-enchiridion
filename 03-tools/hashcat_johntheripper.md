# Password Cracking

1. Identify what the hash or blob likely is
2. Clean the file if needed
3. Choose Hashcat mode or John format
4. Start with a wordlist
5. Add rules if needed
6. Check cracked results


## Hash identification

Useful references:
- [Hashcat example hashes from hashcat wiki](https://hashcat.net/wiki/doku.php?id=example_hashes)
- [github repo table with example hashes for hashcat](https://gist.github.com/CalfCrusher/6b87a738d0fe7b88e04f4a36eb6d722d)

| Pattern | Likely Meaning |
|---|---|
| plaintext | readable word or phrase, not a hash |
| 32 hex chars | often MD5 |
| 40 hex chars | often SHA1 |
| 64 hex chars | often SHA256 |
| 16 or 13 chars | could be old DES / Unix crypt variants |
| starts with `$2a$`, `$2b$`, `$2y$` | bcrypt |
| starts with `$1$` | md5crypt |
| starts with `$5$` | sha256crypt |
| starts with `$6$` | sha512crypt |
| starts with `$krb5asrep$23$` | Kerberos AS-REP roast |
| starts with `$krb5pa$23$` or similar pre-auth format | Kerberos pre-auth material |
| starts with `sha1$`, `md5$`, `pbkdf2`, `argon2` | framework-specific or modern KDF |
| looks like base64 with `/`, `+`, `=` | may be encoded data or a non-raw hash format |

## Clean up hash files

If the extracted material contains stray spaces or line breaks, clean it first.

```bash
# Show the first line
└─$ sed -n '1p' krbtgt_dirty.hash

# Remove whitespace
└─$ tr -d '[:space:]' < krbtgt_dirty.hash > krbtgt.hash
```


---

# hashcat


```text
 /\_/\
( o.o )
 > ^ <
```

`hashcat` is a password recovery utility - [hashcat github repo](https://github.com/hashcat/hashcat)

**Common Hashcat modes**

| Hash Type                                     | Hashcat Mode |
| --------------------------------------------- | -----------: |
| MD5                                           |            0 |
| NTLM                                          |         1000 |
| NetNTLMv2                                     |         5600 |
| phpass / WordPress / phpBB3 MD5               |          400 |
| md5crypt (`$1$`)                              |          500 |
| descrypt / traditional DES                    |         1500 |
| sha256crypt (`$5$`)                           |         7400 |
| sha512crypt (`$6$`)                           |         1800 |
| LM                                            |         3000 |
| bcrypt (`$2a$`, `$2b$`, `$2y$`)               |         3200 |
| DCC / MS Cache                                |         1100 |
| DCC2 / MS Cache 2                             |         2100 |
| Kerberos 5, etype 23, TGS-REP (Kerberoasting) |        13100 |
| Kerberos 5, etype 23, AS-REQ Pre-Auth         |         7500 |
| Kerberos 5, etype 23, AS-REP                  |        18200 |
| WPA-PBKID-PMKID+EAPOL                         |        22000 |
| KeePass                                       |        13400 |
fast lookup during pentesting: - [github repo table with example hashes for hashcat](https://gist.github.com/CalfCrusher/6b87a738d0fe7b88e04f4a36eb6d722d)


NTLM
```bash
sudo hashcat -m 1000 ntlm.hash /usr/share/wordlists/rockyou.txt
```

MD5
```bash
sudo hashcat -m 0 md5.hash /usr/share/wordlists/rockyou.txt
```

sha512crypt
```bash
sudo hashcat -m 1800 shadow.hash /usr/share/wordlists/rockyou.txt
```

AS-REP roast with rules
```bash
sudo hashcat -m 18200 admin.hash /usr/share/wordlists/rockyou.txt -r /usr/share/hashcat/rules/best64.rule --force 
```

show cracked results
```bash
sudo hashcat -m 1000 ntlm.hash --show
```

- `-m` = hash mode
- `-r` = apply rule file
- `--force` = force execution even if `hashcat` warns about environment issues  
- `--show` = display already cracked hashes
- `--username` = useful when input includes usernames before hashes
- running with `sudo` is useful when you want to give GPU device permissions

---

# john the ripper

another awesome very fast password cracker is `john` or John the Ripper - [John the Ripper Github Repo](https://github.com/openwall/john)

useful when:
- a format is easier to load into John
- you are working with `/etc/shadow`
- you want quick format autodetection
- you want to check already-cracked results easily

**Common IDs

| Hash Type | John Format | Hashcat Mode |  
|---|---|---:|  
| MD5 (`$1$`) | `md5crypt` | `500` |  
| SHA-256 (`$5$`) | `sha256crypt` | `7400` |  
| SHA-512 (`$6$`) | `sha512crypt` | `1800` |  
| bcrypt (`$2a$`, `$2b$`, `$2y$`) | `bcrypt` | `3200` |  
| NTLM | `NT` | `1000` |  
| LM | `LM` | `3000` |  
| phpass / WordPress / phpBB3 MD5 | `phpass` | `400` |  
| NetNTLMv2 | `netntlmv2` | `5600` |  
| DCC / MS Cache | `mscash` | `1100` |  
| DCC2 / MS Cache 2 | `mscash2` | `2100` |  
| descrypt / traditional DES | `descrypt` | `1500` |
SSH hash cracking
```bash
└─$ john --wordlist=/usr/share/wordlists/rockyou.txt ssh.txt   
```

show cracked result
```bash
└─$ john --show shadow.txt

user:password:ID:0:99999:7:::
```

`/etc/shadow` format for john
```bash
username:$id$salt$hash:lastchange:min:max:warn:inactive:expire
```

cracking shadow hashes with john
```bash
└─$ john --wordlist=/usr/share/wordlists/rockyou.txt shadow.txt
```

other examples
```bash
# md5crypt
john --format=md5crypt --wordlist=/usr/share/wordlists/rockyou.txt shadow.txt

# sha256crypt
john --format=sha256crypt --wordlist=/usr/share/wordlists/rockyou.txt shadow.txt

# sha512crypt
john --format=sha512crypt --wordlist=/usr/share/wordlists/rockyou.txt shadow.txt

# bcrypt
john --format=bcrypt --wordlist=/usr/share/wordlists/rockyou.txt hashes.txt

# NTLM
john --format=NT --wordlist=/usr/share/wordlists/rockyou.txt ntlm.txt

# NetNTLMv2
john --format=netntlmv2 --wordlist=/usr/share/wordlists/rockyou.txt netntlmv2.txt

# show cracked results
john --show hashes.txt
```


---

Katzen sind süß, und vor allem finde ich Mona sehr nice, ein bekanntes ASCII-Kätzchen

```text

　　 彡 ⌒ ミ　 　♪　彡 ⌒ ミ　　　　　彡 ⌒ ミ　♪　　彡 ⌒ミ　♪
　　(´・ω・`)　　　　　(´・ω・`)　♪　　(´・ω・`)　　　　(´・ω・`)　　♪
　　（ つ　つ 　　　　　（ つ　つ 　　　 （ つ　つ 　　　　（ つ　つ
((　（⌒ __)　)) 　　((　（⌒ __)　)) 　((　（⌒ __)　)) 　((　（⌒ __)　))
　　　し' っ 　　　　　　　し' っ 　　　　　　し' っ 　　　　　　し' っ　

```
<sub>source of <a href="https://2ch-aa.blogspot.com/2018/06/625.html"> katzen ascii art </a></sub>

