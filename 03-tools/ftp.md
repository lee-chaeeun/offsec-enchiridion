# FTP  
  
FTP is a file transfer protocol commonly found on TCP port `21`. 
- During enumeration, check for anonymous login, readable/writable directories, version information, and files that may contain credentials or application data.  
  
Service detection  
```bash  
nmap -sV -sC -p 21 target_ip
```

```bash
ftp target_ip
ftp target_ip -p port_num
```

Inside FTP:
```bash
binary  
ls  
get filename

# Download all files in the current directory:
mget *

# Upload files
put filename
ls
```

Useful enumeration
```bash
# Check for anonymous access with Nmap
nmap --script ftp-anon -p 21 target_ip

# Check FTP scripts
nmap --script "ftp-*" -p 21 target_ip

# Banner grabbing
nc -nv target_ip 21
```

