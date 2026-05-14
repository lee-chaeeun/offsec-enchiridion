### RPC

RPC can help enumerate:
- domain users
- domain groups
- local users
- password policy
- shares indirectly
- domain SID
- logged-on / session-related info sometimes
- workstation/domain info
- RID cycling when allowed

Common ports:
```bash
135/tcp msrpc
139/tcp netbios-ssn  
445/tcp microsoft-ds
```

```bash
# anon
rpcclient -U "" -N target_ip

# credentials
rpcclient -U "domain.com/username%password" target_ip
```

Useful commands inside `rpcclient`:
```
srvinfo
enumdomusers
enumdomgroups
querydominfo
getdompwinfo
lookupnames username
lookupsids SID
lsaquery
```


```bash
impacket-rpcdump target_ip

impacket-rpcdump domain.com/username:'password'@target_ip
```
Use:
- identify exposed RPC interfaces
- support attack surface analysis
- useful when port `135` is open but you are unsure what is exposed


```bash
enum4linux-ng -A target_ip

enum4linux-ng -A -u username -p 'password' target_ip
```
Use:
- quick SMB/RPC overview
- users/groups/shares/policy
- good first pass, then manually validate with `rpcclient`


## RID cycling

If anonymous or low-priv RPC allows SID lookups, you may enumerate users by RID.

```bash
# get domain SID
lsaquery

# lookup common RIDs
lookupsids S-1-5-21-domain-sid-500  
lookupsids S-1-5-21-domain-sid-501  
lookupsids S-1-5-21-domain-sid-512
```

- `500` often maps to Administrator
- `501` often maps to Guest
- `512` often maps to Domain Admins

