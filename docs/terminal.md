# Terminal — Kitty & Tmux

## Kitty — Terminal Emulator
Fast GPU-accelerated terminal with Wayland support.

### Settings
| Setting | Value |
|---|---|
| Font | JetBrainsMono Nerd Font — size 12 |
| Opacity | 92% |
| Background | `#0b0b0e` (very dark) |
| Foreground | `#e0e0e0` |
| Cursor | beam |
| Padding | 4px |
| Scrollback | 10,000 lines |
| Colors | Catppuccin Mocha (16 ANSI colors) |
| Bell | disabled |

### Keybindings
| Key | Action |
|---|---|
| `Ctrl+Shift+C` | Copy |
| `Ctrl+Shift+V` | Paste |
| `Ctrl+Shift+Up/Down` | Scroll line up/down |
| `Ctrl+Shift+PageUp/Down` | Scroll page up/down |
| `Ctrl+Shift+Home/End` | Scroll to top/bottom |
| `Ctrl+Shift+F` | Show scrollback buffer |

---

## Tmux — Terminal Multiplexer
Multiple windows and panes in one terminal. SSH session persistence.

### Settings
| Setting | Value | Description |
|---|---|---|
| prefix | `Ctrl+A` | Key to start all commands |
| numbering | from 1 | Windows start at 1 (not 0) |
| escape time | 10ms | Fast escape for nvim |
| key mode | vi | Vim keys in scroll mode |
| mouse | enabled | Click, drag, scroll |
| colors | 256 + true color | Full color support |
| history | 50,000 lines | Large scrollback |

### Concepts
```
Session (session)
  └── Window (window) — like a tab
       └── Pane (pane) — like a split
```

- **Session:** Independent work session. Can detach and reattach later.
- **Window:** Like browser tab. Each window can have multiple panes.
- **Pane:** Part of a window. Can split horizontally or vertically.

### Keybindings

> All keybindings work after pressing `Ctrl+A` (prefix).

#### Window Management
| Key | Action |
|---|---|
| `Ctrl+A` + `c` | New window |
| `Ctrl+A` + `n` | Next window |
| `Ctrl+A` + `p` | Previous window |
| `Ctrl+A` + `0-9` | Go to window N |
| `Ctrl+A` + `w` | List windows (selectable) |
| `Ctrl+A` + `,` | Rename current window |
| `Ctrl+A` + `&` | Close current window |

#### Pane Management
| Key | Action |
|---|---|
| `Ctrl+A` + `\|` | Split vertical |
| `Ctrl+A` + `-` | Split horizontal |
| `Ctrl+A` + `h/j/k/l` | Move to pane (vim-style) |
| `Ctrl+A` + `x` | Close current pane |
| `Ctrl+A` + `z` | Zoom pane (fullscreen toggle) |
| `Ctrl+A` + `{` | Move pane left |
| `Ctrl+A` + `}` | Move pane right |
| `Ctrl+A` + `H/J/K/L` | Resize pane (5 steps) |

#### Session Management
| Key | Action |
|---|---|
| `Ctrl+A` + `d` | Detach (exit without closing) |
| `Ctrl+A` + `s` | List sessions |
| `Ctrl+A` + `$` | Rename current session |

#### Scroll & Copy
| Key | Action |
|---|---|
| `Ctrl+A` + `[` | Enter scroll mode |
| `j` / `k` | Move up/down (vi mode) |
| `g` / `G` | Go to top/bottom |
| `/` / `?` | Search down/up |
| `Space` | Start selection |
| `Enter` | Copy selection |
| `q` | Exit scroll mode |

#### Other
| Key | Action |
|---|---|
| `Ctrl+A` + `r` | Reload config |
| `Ctrl+A` + `:` | Command mode |
| `Ctrl+A` + `?` | List all keybindings |
| `Shift+Left/Right` | Switch window (direct) |

### Terminal Commands
```bash
tmux                          # new session
tmux new -s project           # named session
tmux ls                       # list sessions
tmux attach -t project        # attach to session
tmux kill-session -t project  # kill session
```

### Usage Patterns

#### Web Development
```
┌──────────────┬──────────────┐
│ nvim (code)  │ terminal     │
│              │              │
├──────────────┤              │
│ terminal     │              │
│ (server)     │              │
└──────────────┴──────────────┘
```

#### Remote Server
```bash
ssh user@server
tmux new -s work
# ... work ...
# if connection drops:
ssh user@server
tmux attach -t work
# → everything is preserved!
```

### Configuration
File: `modules/home/cli/tmux.nix`
