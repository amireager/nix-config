# Dev Tools — Specialized Development Utilities

## Advanced Search & Code Analysis
| Tool | Usage | Purpose |
|---|---|---|
| **ripgrep-all** | `rga "text" *.pdf` | Search inside PDFs, archives, documents |
| **ast-grep** | `sg -p 'console.log($$$)' -l js` | Structural code search & refactor |

## File Tree, Binary & Text
| Tool | Usage | Purpose |
|---|---|---|
| **erdtree** | `erd` | Tree viewer with disk usage |
| **hexyl** | `hexyl file.bin` | Hex viewer |
| **grex** | `grex a1 b2 c3` | Generate regex from examples |
| **dasel** | `dasel -f file.json -s ".name"` | Query JSON/YAML/TOML/XML/CSV |

## Benchmarking & Watching
| Tool | Usage | Purpose |
|---|---|---|
| **hyperfine** | `hyperfine 'fd' 'find . -name "*"'` | Benchmark commands |
| **watchexec** | `watchexec -e py python main.py` | Run on file change |
| **tokei** | `tokei` | Count lines of code by language |

## GitHub & Command Workflow
| Tool | Usage | Purpose |
|---|---|---|
| **gh-dash** | `gh-dash` | GitHub dashboard TUI |
| **navi** | `navi` | Interactive command cheatsheets |

## Network Monitoring & Diagnostics
| Tool | Usage | Purpose |
|---|---|---|
| **iotop** | `sudo iotop` | I/O monitoring per process |
| **nethogs** | `sudo nethogs` | Bandwidth per process |
| **iftop** | `sudo iftop` | Bandwidth per connection |
| **nload** | `nload` | Realtime network throughput |
| **vnstat** | `vnstat` | Network traffic history |
| **iperf3** | `iperf3 -c server` | Network throughput testing |
| **bmon** | `bmon` | Bandwidth monitor TUI |
| **gping** | `gping domain.com` | Ping with terminal graph |
| **traceroute** | `traceroute domain.com` | Classic traceroute |
| **websocat** | `websocat ws://url` | WebSocket client |
| **tcpdump** | `sudo tcpdump -i any` | Packet capture |
| **nmap** | `nmap -sn 192.168.1.0/24` | Network scanner |
| **strace** | `strace -p PID` | Trace syscalls |

## File Transfer & Cloud
| Tool | Usage | Purpose |
|---|---|---|
| **rclone** | `rclone sync local: remote:` | Cloud storage sync |
| **magic-wormhole** | `wormhole send file` | Encrypted file transfer |

## Nix Tools
| Tool | Usage | Purpose |
|---|---|---|
| **nixd** | (editor integration) | Nix LSP |
| **nix-tree** | `nix-tree` | Explore Nix store dependencies |
| **nvd** | `nvd diff /run/current-system ./result` | Diff NixOS generations |
| **nix-search-tv** | `nix-search-tv` | Interactive nixpkgs search |
| **comma** | `, cowsay hello` | Run command without installing |
| **nix-index** | `nix-locate libssl.so` | Find package providing file |
| **nix-output-monitor** | `nom build` | Beautiful build output |

## Dev Media
| Tool | Usage | Purpose |
|---|---|---|
| **freeoffice** | GUI | Lightweight MS Office compatible |
| **pinta** | GUI | Simple image editor |
| **poppler-utils** | `pdftotext file.pdf` | PDF CLI tools |
| **ffmpegthumbnailer** | (auto) | Video thumbnails for file manager |
| **kooha** | GUI | Wayland screen recorder |
