# CLI Tools — Modern Terminal Utilities

## File & Disk

| Tool          | Replace     | Usage                                |
| ------------- | ----------- | ------------------------------------ |
| **duf**       | `df`        | `duf` — disk usage with colors       |
| **dust**      | `du`        | `dust` — disk usage with tree view   |
| **fd**        | `find`      | `fd "pattern"` — fast file search    |
| **eza**       | `ls`        | `ls`, `ll`, `la`, `lt` (aliased)     |
| **lsd**       | `ls`        | `lsd` — alternative modern ls        |
| **ouch**      | `tar/unzip` | `ouch file.zip` — extract any format |
| **glow**      | `cat`       | `glow README.md` — render markdown   |
| **trash-cli** | `rm`        | `trash file` — safe delete           |

## Text, Search & Data

| Tool        | Replace | Usage                                          |
| ----------- | ------- | ---------------------------------------------- |
| **ripgrep** | `grep`  | `rg "pattern"` — fast recursive search         |
| **jq**      | —       | `cat file.json \| jq .name` — JSON processor   |
| **yq-go**   | —       | `cat file.yaml \| yq .key` — YAML processor    |
| **sd**      | `sed`   | `sd 'old' 'new' file` — simple sed replacement |
| **jless**   | —       | `jless file.json` — interactive JSON viewer    |
| **jc**      | —       | `jc lsblk` — convert CLI output to JSON        |

## System Inspection

| Tool          | Replace | Usage                                    |
| ------------- | ------- | ---------------------------------------- |
| **procs**     | `ps`    | `procs`, `procs firefox` — modern ps     |
| **bandwhich** | —       | `sudo bandwhich` — bandwidth per process |
| **lsof**      | —       | `lsof -i :8080` — list open files/ports  |
| **psmisc**    | —       | `pstree`, `killall`, `fuser`             |

## Network & Transfer

| Tool      | Replace | Usage                                             |
| --------- | ------- | ------------------------------------------------- |
| **curl**  | —       | `curl url` — HTTP client                          |
| **wget**  | —       | `wget url` — file downloader                      |
| **xh**    | `curl`  | `xh GET url` — modern HTTP client                 |
| **aria2** | —       | `aria2c -x 16 url` — fast multi-thread downloader |
| **rsync** | —       | `rsync -avz src/ dest/` — file sync               |

## Network Diagnostics

| Tool               | Replace | Usage                                        |
| ------------------ | ------- | -------------------------------------------- |
| **dnsutils**       | —       | `dig`, `nslookup`, `host`                    |
| **doggo**          | `dig`   | `doggo domain.com` — modern DNS client       |
| **mtr**            | `ping`  | `mtr domain.com` — ping + traceroute         |
| **whois**          | —       | `whois domain.com` — domain lookup           |
| **socat**          | —       | Socket relay and debugging                   |
| **proxychains-ng** | —       | `proxychains curl url` — route through proxy |

## Data & File Inspection

| Tool         | Replace | Usage                                   |
| ------------ | ------- | --------------------------------------- |
| **file**     | —       | `file document.pdf` — detect file type  |
| **tailspin** | `tail`  | `tailspin /var/log/syslog` — log viewer |

## Productivity

| Tool           | Replace | Usage                                          |
| -------------- | ------- | ---------------------------------------------- |
| **just**       | `make`  | `just build` — command runner                  |
| **difftastic** | `diff`  | `difft old new` — syntax-aware diff            |
| **gum**        | —       | `gum choose a b c` — interactive shell scripts |
| **pueue**      | —       | `pueue add make` — parallel task queue         |

## Programs (TUI)

| Tool          | Replace    | Usage                                   |
| ------------- | ---------- | --------------------------------------- |
| **bat**       | `cat`      | `bat file.py` — syntax highlighting     |
| **tealdeer**  | `man`      | `tldr tar` — quick command examples     |
| **yazi**      | `ranger`   | `y` (aliased) — file manager            |
| **btop**      | `htop`     | `btop` (aliased `top`) — system monitor |
| **fastfetch** | `neofetch` | `fastfetch` — system info               |
| **lazygit**   | `git`      | `lazygit` — git TUI                     |
