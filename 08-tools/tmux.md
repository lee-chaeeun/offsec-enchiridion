`tmux` is a terminal multiplexer. 
- manage multiple terminal windows/panes from one terminal  
- safely detach/reattach without losing running jobs

| Action                           | Shortcut / Command          |
| -------------------------------- | --------------------------- |
| Start tmux                       | `tmux`                      |
| New named session                | `tmux new -s enum`          |
| List sessions                    | `tmux ls`                   |
| Attach                           | `tmux attach -t enum`       |
| Detach & leave all scans running | `Ctrl+b d`                  |
| New window                       | `Ctrl+b c`                  |
| Next window                      | `Ctrl+b n`                  |
| Previous window                  | `Ctrl+b p`                  |
| Window by number                 | `Ctrl+b 0..9`               |
| Split vertical                   | `Ctrl+b %`                  |
| Split horizontal                 | `Ctrl+b "`                  |
| Move panes                       | `Ctrl+b` + arrow keys       |
| Show tmux windows list           | `Ctrl+b w`                  |
| Kill pane                        | `Ctrl+b x`                  |
| Help                             | `Ctrl+b ?`                  |
| Command prompt                   | `Ctrl+b :`                  |
| Kill session                     | `tmux kill-session -t enum` |

create a new window with a name:
```bash
tmux new-window -t ad-enum -n ldap
```

attach to existing session:
```bash
tmux attach -t ad-enum
```

send command to a specific window manually:
```bash
tmux send-keys -t ad-enum:ldap 'ldapsearch -x ...' C-m
```

create names session 
- good practice to make one session per box
```bash
tmux new -s box1
```

- good practice to make one session per activity
```bash
tmux new -s enum  
tmux new -s exploit  
tmux new -s loot
```

list all tmux sessions
```bash
tmux ls
tmux list-windows -t nmap_scan
```

