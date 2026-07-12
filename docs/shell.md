# Shell — Fish & Shell Tools

## Fish Shell
Modern interactive shell with auto-suggestions, syntax highlighting, and completions built-in.

### Configuration
| Setting | Value |
|---|---|
| greeting | disabled |
| autosuggestion | enabled |
| EDITOR | nvim |
| PAGER | bat |
| MANPAGER | bat (colored) |

### Aliases
| Alias | Command | Purpose |
|---|---|---|
| `ls` | `eza --icons --git` | List with icons |
| `ll` | `eza -l --icons --git --header` | List with details |
| `la` | `eza -la --icons --git --header` | Include hidden |
| `lt` | `eza --tree --level=2` | Directory tree |
| `cat` | `bat --style=plain` | Show file |
| `grep` | `ripgrep` | Search |
| `find` | `fd` | Find files |
| `top` | `btop` | System monitor |
| `cdi` | `zi` | Smart cd (zoxide) |

### Abbreviations
| Abbr | Expansion | Purpose |
|---|---|---|
| `n` | `nvim` | Open editor |
| `y` | `yazi` | File manager |
| `sw` | `nh os switch` | Rebuild system |
| `tst` | `nh os test` | Test system |
| `bld` | `nh os build` | Build system |
| `gs` | `git status` | Git status |
| `ga` | `git add` | Git add |
| `gc` | `git commit -m` | Git commit |
| `gco` | `git checkout` | Git checkout |
| `gcb` | `git checkout -b` | New branch |
| `gp` | `git push` | Git push |
| `gpl` | `git pull --rebase` | Git pull |

### Keybindings
| Key | Action |
|---|---|
| `Ctrl+R` | Search command history (fzf) |
| `Ctrl+T` | Search files (fzf) |
| `Alt+C` | Search directories (fzf) |
| `Ctrl+Space` | Accept autosuggestion |
| `Ctrl+Alt+P` | Kill process (fzf) |
| `Ctrl+Alt+G` | Git log interactive |
| `Ctrl+Alt+B` | Git branch checkout |

### Functions
| Function | Example | Description |
|---|---|---|
| `mkcd` | `mkcd src/api` | Create dir and cd into it |
| `extract` | `extract file.tar.gz` | Extract any archive format |
| `backup` | `backup config.nix` | Quick backup with timestamp |
| `killp` | `killp` | Kill process with fzf |
| `glog` | `glog` | Interactive git log |
| `gco_branch` | `gco_branch` | Interactive branch checkout |

### Plugins
| Plugin | Purpose |
|---|---|
| `colored-man-pages` | Colored man pages |
| `done` | Notification when long command finishes |
| `fzf-fish` | fzf integration (Ctrl+T, Alt+C) |
| `autopair` | Auto-close brackets |
| `forgit` | Git interactive with fzf |

---

## Starship Prompt
Fast, minimal prompt with Git integration.

**Shows:**
- Current directory (blue)
- Git branch (orange) + status (red/green)
- Nix shell indicator (snowflake)
- Command duration
- Time + battery (right side)

---

## Zoxide — Smart cd
`z project` → cd to most used directory matching "project"
`zi` → interactive selection

---

## Direnv — Project Environment Loading
Automatically loads `.envrc` when entering a directory.
Works with `nix develop` for project-specific shells.

---

## FZF — Fuzzy Finder
| Key | Action |
|---|---|
| `Ctrl+T` | Search files (with preview) |
| `Alt+C` | Search directories (with tree preview) |
| `Ctrl+R` | Search command history |
| `Tab` | Multi-select |

---

## Carapace — Extra Completions
Auto-completions for 600+ commands. Works silently in background.
