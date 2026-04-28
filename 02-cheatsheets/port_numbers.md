
# Common Port Numbers and Services

## Quick Enumeration Mapping

| Port             | Usability                                                 |
| ---------------- | --------------------------------------------------------- |
| 21               | Check anonymous FTP and writable directories              |
| 22               | SSH creds, keys, version, brute-force only if appropriate |
| 25               | SMTP user enum, VRFY/EXPN/manual banner checks            |
| 53               | DNS zone transfer, hostname resolution                    |
| 80/443/8080/etc. | Full web enumeration                                      |
| 88/389/445       | Think Active Directory / Windows enum                     |
| 111/2049         | Think NFS                                                 |
| 139/445          | SMB shares, users, policies                               |
| 161              | SNMP can leak a lot very quickly                          |
| 1433             | MSSQL login and xp_cmdshell context                       |
| 3306/5432        | DB creds and local data exposure                          |
| 3389             | Valid Windows creds may be enough                         |
| 5985/5986        | Evil-WinRM if creds are valid                             |
| 6379             | Redis misconfig can be huge                               |
| 8009             | Check for Tomcat/AJP exposure                             |
| 9200             | Elasticsearch exposure                                    |

Pentest tip -> don't fall into a rabbit hole by assuming port number means service X runs there.
- Common port != guaranteed service
- Services can run on non-standard ports
e.g
- HTTP may run on `8000`, `8080`, `8888`, or random high ports
- SSH may run on `2222`
- SMB-like tooling may be hidden behind unusual configs

Solution: must verify ports using
  - banners
  - `nmap -sV`
  - manual probing
  - protocol-specific tools

## High-Value Ports 

| Port  | Protocol | Common Service           | Usability                                                              |
| ----- | -------- | ------------------------ | ---------------------------------------------------------------------- |
| 21    | TCP      | FTP                      | Anonymous login, weak creds, writable shares, file retrieval           |
| 22    | TCP      | SSH                      | Password spraying, key-based auth, banners, tunneling                  |
| 23    | TCP      | Telnet                   | Cleartext auth, weak/default creds                                     |
| 25    | TCP      | SMTP                     | User enumeration, mail relay, phishing/internal comms, mailboxes       |
| 53    | TCP/UDP  | DNS                      | Zone transfers, hostname discovery, AD recon                           |
| 69    | UDP      | TFTP                     | Anonymous file read/write, config leaks                                |
| 80    | TCP      | HTTP                     | Web enumeration, directories, auth, uploads, RCE                       |
| 88    | TCP/UDP  | Kerberos                 | AD target, user enumeration, Kerberoasting/AS-REP roast context        |
| 110   | TCP      | POP3                     | Mail access, creds, cleartext/legacy services                          |
| 111   | TCP/UDP  | rpcbind / portmapper     | NFS and RPC enumeration                                                |
| 123   | UDP      | NTP                      | Occasionally useful for info leakage / time sync context               |
| 135   | TCP      | MSRPC                    | Windows RPC, often paired with SMB/DC enumeration                      |
| 137   | UDP      | NetBIOS-NS               | Legacy Windows name service                                            |
| 138   | UDP      | NetBIOS-DGM              | Legacy Windows enumeration                                             |
| 139   | TCP      | NetBIOS-SSN              | SMB over NetBIOS, old Windows file sharing                             |
| 143   | TCP      | IMAP                     | Mail enumeration and credential testing                                |
| 161   | UDP      | SNMP                     | Huge enumeration value, system info, routes, users, installed software |
| 389   | TCP/UDP  | LDAP                     | AD enumeration, naming contexts, users, groups                         |
| 443   | TCP      | HTTPS                    | Secure web apps, same web attack surface as HTTP                       |
| 445   | TCP      | SMB                      | Shares, null sessions, relay context, user/group info, file access     |
| 464   | TCP/UDP  | kpasswd                  | Kerberos password change service, AD context                           |
| 512   | TCP      | rexec                    | Legacy remote execution                                                |
| 513   | TCP      | rlogin                   | Legacy remote login                                                    |
| 514   | TCP/UDP  | rsh / syslog             | Legacy remote shell or logging                                         |
| 554   | TCP/UDP  | RTSP                     | Camera / streaming targets                                             |
| 587   | TCP      | SMTP Submission          | Authenticated mail submission, creds                                   |
| 593   | TCP      | HTTP-RPC-EPMAP           | Windows RPC over HTTP                                                  |
| 631   | TCP      | IPP / CUPS               | Printer services, sometimes misconfigurations                          |
| 636   | TCP      | LDAPS                    | LDAP over SSL, AD enumeration                                          |
| 873   | TCP      | rsync                    | Anonymous shares, file retrieval                                       |
| 993   | TCP      | IMAPS                    | Secure IMAP                                                            |
| 995   | TCP      | POP3S                    | Secure POP3                                                            |
| 1025+ | TCP      | High RPC ports           | Windows RPC dynamic ports                                              |
| 1080  | TCP      | SOCKS proxy              | Pivoting / proxying opportunity                                        |
| 1099  | TCP      | Java RMI Registry        | Java exploitation surface                                              |
| 1433  | TCP      | MSSQL                    | SQL auth, xp_cmdshell context, Windows domain integration              |
| 1521  | TCP      | Oracle                   | DB enumeration, creds, legacy enterprise targets                       |
| 1723  | TCP      | PPTP                     | VPN endpoint                                                           |
| 1883  | TCP      | MQTT                     | IoT / message broker targets                                           |
| 2049  | TCP/UDP  | NFS                      | Mountable shares, no_root_squash, sensitive files                      |
| 2375  | TCP      | Docker (unencrypted)     | High-value misconfig, container breakout context                       |
| 2376  | TCP      | Docker TLS               | Docker daemon exposure                                                 |
| 3128  | TCP      | Squid proxy              | Proxy abuse / pivoting                                                 |
| 3306  | TCP      | MySQL                    | DB access, creds, file read/write functions                            |
| 3389  | TCP      | RDP                      | Remote desktop, creds, NLA, GUI access                                 |
| 3632  | TCP      | distccd                  | Famous RCE target in older systems                                     |
| 3690  | TCP      | Subversion (SVN)         | Source code leakage                                                    |
| 4369  | TCP      | Erlang Port Mapper       | RabbitMQ / Erlang ecosystem                                            |
| 5000  | TCP      | Web / custom apps        | Flask, APIs, management panels                                         |
| 5432  | TCP      | PostgreSQL               | DB access, creds, command execution context                            |
| 5601  | TCP      | Kibana                   | Dashboard misconfig / old vulns                                        |
| 5672  | TCP      | AMQP / RabbitMQ          | Messaging infra, admin panels                                          |
| 5900  | TCP      | VNC                      | Remote desktop, weak/no auth                                           |
| 5985  | TCP      | WinRM (HTTP)             | Great for shells with valid creds                                      |
| 5986  | TCP      | WinRM (HTTPS)            | Same as above, over TLS                                                |
| 6000  | TCP      | X11                      | GUI exposure / trust issues                                            |
| 6379  | TCP      | Redis                    | Unauth access, file write, SSH key abuse                               |
| 6667  | TCP      | IRC                      | Legacy services / bots                                                 |
| 7001  | TCP      | WebLogic                 | Enterprise Java target                                                 |
| 8000  | TCP      | Web / alt HTTP           | Dev servers, dashboards                                                |
| 8009  | TCP      | AJP                      | Tomcat Ghostcat-style context                                          |
| 8080  | TCP      | HTTP-alt                 | Proxies, Tomcat, admin panels                                          |
| 8081  | TCP      | HTTP-alt                 | App consoles / management panels                                       |
| 8086  | TCP      | InfluxDB                 | Metrics/data platforms                                                 |
| 8443  | TCP      | HTTPS-alt                | Admin portals, appliances                                              |
| 8888  | TCP      | Web / Jupyter            | Notebook exposure, tokens, code exec                                   |
| 9000  | TCP      | SonarQube / custom apps  | Source and admin interfaces                                            |
| 9090  | TCP      | Web console / Prometheus | Monitoring/admin exposure                                              |
| 9200  | TCP      | Elasticsearch            | Unauth data exposure / cluster info                                    |
| 9418  | TCP      | Git                      | Source code leakage                                                    |
| 9999  | TCP      | Web / admin / custom     | Check banners carefully                                                |
| 11211 | TCP/UDP  | Memcached                | Info leak / exposure                                                   |
| 27017 | TCP      | MongoDB                  | Unauth DB exposure on older/misconfigured setups                       |

## Active Directory / Windows Ports

| Port | Service                  | Usability                                 |
| ---- | ------------------------ | ----------------------------------------- |
| 53   | DNS                      | Domain discovery, records, zone transfers |
| 88   | Kerberos                 | Domain auth, roasting context             |
| 135  | MSRPC                    | RPC services and enumeration              |
| 139  | NetBIOS                  | Legacy SMB-related enumeration            |
| 389  | LDAP                     | Users, groups, naming contexts, AD info   |
| 445  | SMB                      | Shares, policies, users, relay context    |
| 464  | Kerberos Password Change | AD-related service                        |
| 593  | RPC over HTTP            | Windows RPC service exposure              |
| 636  | LDAPS                    | Secure LDAP                               |
| 3268 | Global Catalog LDAP      | Forest-wide object queries                |
| 3269 | Global Catalog LDAPS     | Secure global catalog                     |
| 3389 | RDP                      | GUI access with creds                     |
| 5985 | WinRM HTTP               | Remote PowerShell with creds              |
| 5986 | WinRM HTTPS              | Same over TLS                             |

if following ports active -> likely to be Domain Controller or AD-connected Windows host 
- 53
- 88
- 135
- 139
- 389
- 445
- 464
- 636
- 3268
- 3269


## Linux Ports

| Port | Service    | Usability                             |
| ---- | ---------- | ------------------------------------- |
| 21   | FTP        | Anonymous access, upload/write, creds |
| 22   | SSH        | Creds, keys, tunneling                |
| 25   | SMTP       | Users, relay, mail                    |
| 53   | DNS        | Zone transfer, hostnames              |
| 69   | TFTP       | Read/write files                      |
| 111  | rpcbind    | NFS/RPC enumeration                   |
| 161  | SNMP       | System info, users, routes, processes |
| 2049 | NFS        | Exported shares, permissions          |
| 3306 | MySQL      | Creds, DB access                      |
| 5432 | PostgreSQL | Creds, DB access                      |
| 6379 | Redis      | Unauth access, file write             |
| 873  | rsync      | Anonymous shares                      |
| 9418 | Git        | Source repo access                    |

## Web Ports 

| Port | Service Pattern   | Usability                          |
| ---- | ----------------- | ---------------------------------- |
| 80   | HTTP              | Standard web enum target           |
| 443  | HTTPS             | Same as 80, check certs and vhosts |
| 8000 | Alt HTTP          | Dev server / API / app             |
| 8080 | Alt HTTP          | Tomcat, proxy, dashboards          |
| 8081 | Alt HTTP          | Admin panels                       |
| 8443 | Alt HTTPS         | Admin portals, appliances          |
| 8888 | Web app / Jupyter | High-value misconfigurations       |
| 5000 | Flask/API/custom  | Developer tooling or custom app    |
| 9000 | Custom/admin      | SonarQube or app panel             |
| 9090 | Monitoring/admin  | Prometheus or app console          |

## Database Ports

| Port  | DB         | Usability                                          |
| ----- | ---------- | -------------------------------------------------- |
| 1433  | MSSQL      | SQL auth, domain integration, command exec context |
| 1521  | Oracle     | SID/service names, default creds                   |
| 3306  | MySQL      | Weak creds, local file access                      |
| 5432  | PostgreSQL | Default creds, DB access                           |
| 27017 | MongoDB    | Unauth access, exposed data                        |
| 6379  | Redis      | Unauth access, file write tricks                   |

## Remote Access / Shell Access Ports

| Port | Service          | Usability                       |
| ---- | ---------------- | ------------------------------- |
| 22   | SSH              | Linux shell with creds/keys     |
| 23   | Telnet           | Legacy cleartext remote login   |
| 3389 | RDP              | Windows GUI access              |
| 5900 | VNC              | Remote desktop, often weak auth |
| 5985 | WinRM            | Great for Windows shell access  |
| 5986 | WinRM over HTTPS | Same, encrypted                 |
| 512  | rexec            | Legacy remote exec              |
| 513  | rlogin           | Legacy remote login             |
| 514  | rsh              | Legacy remote shell             |

## Mail Ports

| Port | Service         | Usability              |
| ---- | --------------- | ---------------------- |
| 25   | SMTP            | User enum, relay, auth |
| 110  | POP3            | Mail retrieval, creds  |
| 143  | IMAP            | Mail retrieval, creds  |
| 587  | SMTP Submission | Authenticated SMTP     |
| 993  | IMAPS           | Secure IMAP            |
| 995  | POP3S           | Secure POP3            |





