# Documentation — Amir's NixOS Configuration

## System
| File | Topic |
|---|---|
| [system.md](./system.md) | Core system, kernel, hardware, Nix settings |
| [nix-workflow.md](./nix-workflow.md) | Nix tools, daily commands, system management |
| [network.md](./network.md) | DNS, proxy, firewall, network tools |

## Shell & Terminal
| File | Topic |
|---|---|
| [shell.md](./shell.md) | Fish, Starship, Zoxide, Direnv, FZF, Carapace |
| [terminal.md](./terminal.md) | Kitty, Tmux (with all keybindings) |
| [cli-tools.md](./cli-tools.md) | All modern CLI tools (eza, bat, ripgrep, ...) |

## Development & Editor
| File | Topic |
|---|---|
| [editor.md](./editor.md) | Neovim (LSP, Treesitter, keybindings, plugins) |
| [dev-tools.md](./dev-tools.md) | Dev tools (tokei, watchexec, lazygit, ...) |

## GUI & Desktop
| File | Topic |
|---|---|
| [desktop.md](./desktop.md) | Niri compositor, Noctalia, Wayland tools |
| [browser.md](./browser.md) | Browsers (Zen, Qutebrowser, Brave) |
| [media.md](./media.md) | Media tools, office, camera, screen recording |
| [git.md](./git.md) | Git, Delta, GitHub CLI |

## Philosophy
- **Light, fast, CLI-first**
- Modern terminal tools replace classic ones
- DevShell for specialized tools (direnv auto-loads)
- Tiling desktop without overhead (Niri)
- Development with Neovim + Tmux

## Quick Reference
| Item | Value |
|---|---|
| User | `amir` |
| Shell | Fish |
| Editor | Neovim |
| Terminal | Kitty |
| Multiplexer | Tmux (prefix: `Ctrl+A`) |
| Desktop | Niri (Wayland tiling) |
| Default browser | Zen Browser |
| Rebuild command | `nh os switch` |
