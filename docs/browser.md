# Browsers

## Zen Browser (Default)

Firefox-based with Arc-like UX. Vertical tabs, clean workspace.

**Installed via:** flake (`zen-browser-flake`)

**Features:**

- Vertical tabs on the left
- Workspaces
- Firefox extension support
- Modern minimal design

**Wayland:**

```
MOZ_ENABLE_WAYLAND=1   # set in environment variables
```

**Keybindings:**
| Key | Action |
|---|---|
| `Ctrl+T` | New tab |
| `Ctrl+W` | Close tab |
| `Ctrl+Shift+T` | Restore closed tab |
| `Ctrl+L` | Focus address bar |
| `Ctrl+Tab` | Next tab |
| `Ctrl+Shift+Tab` | Previous tab |
| `F11` | Fullscreen |

**Default app for:** HTML, HTTP/HTTPS links

---

## Qutebrowser

Keyboard-driven browser with vim-like navigation.

**Installed via:** nixpkgs (`pkgs.qutebrowser`)

**Features:**

- 100% keyboard control
- No mouse needed
- Python scriptable
- Lightweight and fast

**Keybindings:**
| Key | Action |
|---|---|
| `o` | Open URL |
| `O` | Open URL in current tab |
| `t` | New tab |
| `d` | Close tab |
| `J` / `K` | Previous / next tab |
| `r` | Reload |
| `R` | Reload without cache |
| `H` / `L` | Back / forward |
| `/` | Search in page |
| `n` / `N` | Next / prev match |
| `gg` | Top of page |
| `G` | Bottom of page |
| `h/j/k/l` | Movement (vim-style) |
| `f` | Follow link (hint mode) |
| `F` | Follow link in new tab |
| `:` | Command mode |
| `q` | Quit |

---

## Brave

Chromium-based with built-in privacy features.

**Installed via:** nixpkgs (`pkgs.brave`)

**Features:**

- Built-in ad blocker (Brave Shields)
- Tracker blocker
- HTTPS Everywhere built-in
- Chrome extension compatible
- Tor in private window

**Wayland:**

```bash
brave --ozone-platform=wayland
```

**Keybindings:**
| Key | Action |
|---|---|
| `Ctrl+T` | New tab |
| `Ctrl+W` | Close tab |
| `Ctrl+Shift+T` | Restore closed tab |
| `Ctrl+L` | Focus address bar |
| `Ctrl+Shift+N` | Private window |
| `F12` | Developer tools |
| `Ctrl+Shift+Delete` | Clear browsing data |

---

## Choosing a Browser

| Need            | Browser                                    |
| --------------- | ------------------------------------------ |
| Daily use       | **Zen Browser** — modern UX, vertical tabs |
| Keyboard-driven | **Qutebrowser** — no mouse needed          |
| Privacy         | **Brave** — built-in blocker and Tor       |
| Speed           | **Thorium** — AppImage (if needed)         |

## Default Browser

Zen Browser is set as default:

- Opening links → Zen Browser
- HTML files → Zen Browser
- `http://` and `https://` → Zen Browser

Configured in `modules/home/gui/xdg.nix`.
