# Gobuster 

Gobuster = content discovery tool for brute-forcing web paths, files, DNS names, vhosts, and S3 buckets.
- directory discovery  
- file discovery  
- extension-based discovery  
- virtual host discovery  
- quick validation of hidden paths

Strategy adapt based on findings
- PHP app -> add `-x php,txt,bak,zip`
- login found -> test authenticated enumeration
- hostname redirect -> add `/etc/hosts` entry
- vhost suspected -> run `gobuster vhost`
- 403 found -> inspect manually, it may still matter

## Directory Enumeration

```bash
gobuster dir -u http://target_ip \  
-w /usr/share/wordlists/dirb/common.txt \  
-t 10

# With extensions:
gobuster dir -u http://TARGET_IP \
-w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt \
-x txt,html,php,asp,aspx,pdf,bak,zip,conf,config \
-t 10

# status-code filtering
# hide common noise
gobuster dir -u http://TARGET_IP/ \  
-w /usr/share/wordlists/dirb/common.txt \  
-b 404,403 \  
-t 10

# show only useful status codes
gobuster dir -u http://target_ip \  
-w /usr/share/wordlists/dirb/common.txt \  
-s 200,204,301,302,307,401,403 \  
-t 10

# HTTPS target
# `-k` ignores TLS certificate errors.
gobuster dir -u https://target_ip \  
-w /usr/share/wordlists/dirb/common.txt \  
-k \  
-t 10

# output to file 
gobuster dir -u http://target_ip \
-w /usr/share/wordlists/dirb/common.txt \
-o gobuster_target_ip.txt \
-t 10
```

|Code|Meaning|What to do|
|---|---|---|
|200|OK|Visit manually|
|204|No content|Check path/context|
|301 / 302|Redirect|Follow redirect|
|307 / 308|Redirect|Follow redirect|
|401|Auth required|Protected area|
|403|Forbidden|Resource likely exists|
|405|Method not allowed|Try other HTTP methods|
|500|Server error|Check manually, possible interesting path|

| Option      | Use                             |
| ----------- | ------------------------------- |
| `dir`       | directory/file brute force mode |
| `-u`        | target URL                      |
| `-w`        | wordlist                        |
| `-x`        | file extensions                 |
| `-t`        | threads                         |
| `-o`        | output file                     |
| `-k`        | ignore TLS certificate errors   |
| `-b`        | blacklist status codes          |
| `-s`        | show only selected status codes |
| `-r`        | follow redirects                |
| `-a`        | custom User-Agent               |
| `-H`        | custom header                   |
| `-c`        | cookie                          |
| `--timeout` | request timeout                 |
| `--delay`   | delay between requests          |

```text  
# Interesting paths
/admin  
/administrator  
/login  
/dashboard  
/upload  
/uploads  
/files  
/images  
/assets  
/api  
/api/v1  
/backup  
/backups  
/db  
/dev  
/test  
/server-status  
/robots.txt  
/sitemap.xml  
```

also check
```
/.git  
/.svn  
/.env  
/config  
/config.php  
/database  
/database.sql  
/backup.zip  
/site_backup.zip  
/index.php.bak  
/web.config
```

When Gobuster finds something interesting:
- [ ]  Visit path in browser
- [ ]  Check response code
- [ ]  Check response size
- [ ]  Follow redirects
- [ ]  Check source code
- [ ]  Test auth requirements
- [ ]  Try common extensions
- [ ]  Check if directory listing is enabled
- [ ]  Check if uploads are executable
- [ ]  Add vhosts to `/etc/hosts` if needed


## More commands

```bash
# Follow Redirects
# Useful when many paths redirect to login or another endpoint.
gobuster dir -u http://target_ip \
-w /usr/share/wordlists/dirb/common.txt \
-r \
-t 10

# Custom User-Agent
# Useful if default tool User-Agent is blocked.
gobuster dir -u http://target_ip \
-w /usr/share/wordlists/dirb/common.txt \
-a "Mozilla/5.0" \
-t 10


# Authenticated Gobuster
# Use when you have a valid session cookie.
gobuster dir -u http://target_ip \
-w /usr/share/wordlists/dirb/common.txt \
-c "PHPSESSID=session_value" \
-t 10

# With custom header:
gobuster dir -u http://target_ip \
-w /usr/share/wordlists/dirb/common.txt \
-H "Authorization: Bearer token_value" \
-t 10

# With Basic Auth:
gobuster dir -u http://target_ip \
-w /usr/share/wordlists/dirb/common.txt \
-U username \
-P 'password' \
-t 10

# Virtual Host Enumeration
# Use when the web app depends on hostnames or vhosts.

# Basic vhost scan
gobuster vhost -u http://target_ip \
-w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt \
-t 10

# Append domain
gobuster vhost -u http://domain.com \
-w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt \
--append-domain \
-t 10

# Example result:
# Found: admin.domain.com Status: 200 [Size: 1234]
# Found: dev.domain.com Status: 403 [Size: 567]
# Add found vhosts to /etc/hosts:
sudo nano /etc/hosts

# Example:
target_ip domain.com admin.domain.com dev.domain.com

# Then browse:
http://admin.domain.com
http://dev.domain.com

# DNS Enumeration
# Use when DNS is in scope and a domain is known.
gobuster dns -d domain.com \-w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt \-t 10


# Add Cookies or Headers
gobuster dir -u http://target_ip/ \
-w /usr/share/wordlists/dirb/common.txt \
-H "Cookie: session=session_value" \
-t 10

# Custom Host header:
gobuster dir -u http://target_ip/ \
-w /usr/share/wordlists/dirb/common.txt \
-H "Host: target.com" \
-t 10


```

## Extension Strategy

Start small:
```bash
-x txt,html,php
```

Then expand if useful:

```bash
-x txt,html,php,asp,aspx,pdf,bak,zip,conf,config,old,tar,gz
```

Common extension sets:

|Stack|Extensions|
|---|---|
|PHP|`php,txt,bak,zip,conf,config`|
|ASP.NET|`aspx,asp,config,txt,bak,zip`|
|Static|`html,txt,pdf,zip,bak`|
|Unknown|`txt,html,php,asp,aspx,bak,zip,config`|

### API Enumeration

Common API patterns:  
  
```text  
/api  
/api/v1  
/api/v2  
/users/v1  
/books/v1  
/admin/api  
/graphql  
/swagger  
/swagger.json  
/openapi.json  
```

Gobuster with patterns:  
  
```bash  
cat > patterns.txt << 'EOF'  
{GOBUSTER}/v1  
{GOBUSTER}/v2  
api/{GOBUSTER}  
EOF  
```

```bash
gobuster dir -u http://TARGET_IP:PORT/ \  
-w /usr/share/wordlists/dirb/big.txt \  
-p patterns.txt  
```

GET request with headers:  
```bash  
curl -i http://TARGET_IP:PORT/api/v1/users  
```



## Troubleshooting

- forgetting `http://` or `https://`
- using HTTPS without `-k` when cert errors exist
- running huge wordlists too early
- ignoring `403` results
- ignoring redirects
- forgetting vhost enumeration
- not using extensions on PHP/ASPX apps
- not rerunning Gobuster after finding a valid vhost
- not using cookies for authenticated areas
- relying only on Gobuster instead of manual browsing

