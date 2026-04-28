
**Kerberoastable Users**

```cmd
:: Native command
setspn -L SERVICE_ACCOUNT

Registered ServicePrincipalNames for CN=SERVICE_ACCOUNT,CN=Users,DC=domain,DC=local:
        HTTP/WEB_HOSTNAME.domain.local
        HTTP/WEB_HOSTNAME
        HTTP/WEB_HOSTNAME.domain.local:80
```

```powershell
# using ldapsearch 
LDAPSearch -LDAPQuery "(&(objectCategory=user)(servicePrincipalName=*))"

# powerview
Get-DomainUser -SPN
```

user account + SPN may be Kerberoastable  
→ see kerberos-attacks.md

**AS-REP Roastable Users**

```powershell
# ldapsearch
LDAPSearch -LDAPQuery "(&(objectCategory=user)(userAccountControl:1.2.840.113556.1.4.803:=4194304))"

# powerview
Get-DomainUser -PreauthNotRequired
```
pre-auth disabled → may request AS-REP hash

**Delegation Candidates**
```powershell
# powerview
Get-DomainComputer -Unconstrained
Get-DomainUser -TrustedToAuth
Get-DomainComputer -TrustedToAuth
```

delegation findings can create Kerberos attack paths

