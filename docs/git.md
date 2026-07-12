# Git — Version Control

## Git
Distributed version control.

### Aliases (defined in config)
```bash
git st              # git status -sb (summary)
git lg              # git log --oneline --graph --decorate --all
git last            # git log -1 HEAD --stat
git unstage         # git reset HEAD --
git amend           # git commit --amend --no-edit
```

### Shell Aliases (in fish)
| Alias | Command |
|---|---|
| `gst` | `git status --short --branch` |
| `gaa` | `git add --all` |
| `gl` | `git log --oneline --graph --decorate` |
| `gd` | `git diff` |
| `gds` | `git diff --staged` |
| `gclean` | `git clean -fd` |
| `gsta` | `git stash` |
| `gstp` | `git stash pop` |

### Shell Abbreviations
| Abbr | Expansion |
|---|---|
| `gs` | `git status` |
| `ga` | `git add` |
| `gc` | `git commit -m` |
| `gco` | `git checkout` |
| `gcb` | `git checkout -b` |
| `gp` | `git push` |
| `gpl` | `git pull --rebase` |

### Key Settings
| Setting | Value | Description |
|---|---|---|
| `pull.rebase` | true | pull always rebases |
| `push.autoSetupRemote` | true | auto-set upstream on first push |
| `fetch.prune` | true | delete remote-tracking branches |
| `rebase.autoStash` | true | auto-stash before rebase |
| `merge.conflictStyle` | zdiff3 | better conflict display |
| `commit.verbose` | true | show diff in commit message editor |
| `branch.sort` | -committerdate | sort branches by recent commit |
| `core.quotePath` | false | handle Persian/Arabic filenames |

### Git Aliases (in git config)
| Alias | Command |
|---|---|
| `st` | `status -sb` |
| `lg` | `log --oneline --graph --decorate --all` |
| `last` | `log -1 HEAD --stat` |
| `unstage` | `reset HEAD --` |
| `amend` | `commit --amend --no-edit` |

---

## Delta — Beautiful Diff
Syntax-highlighted diff viewer integrated with git.

**Configured:**
- Line numbers: enabled
- Side-by-side: disabled
- Theme: ansi
- Navigation: enabled

**Usage (automatic via git):**
```bash
git diff            # → displayed with delta
git log -p          # → displayed with delta
git show            # → displayed with delta
```

**Keybindings (in delta):**
| Key | Action |
|---|---|
| `n` | Next match |
| `N` | Previous match |
| `q` | Quit |

---

## GitHub CLI — gh
Command-line interface for GitHub.

**Configured:** `git_protocol = "ssh"`

### Common Commands
```bash
gh auth login           # authenticate
gh repo clone owner/repo # clone repo
gh pr list              # list pull requests
gh pr create            # create PR
gh pr merge 42          # merge PR #42
gh issue create         # create issue
gh issue list           # list issues
gh gist create file     # create gist
```

---

## Lazygit — Git TUI
Terminal UI for git. No need to type commands.

```bash
lazygit                 # open lazygit
```

### Keybindings
| Key | Action |
|---|---|
| `1-5` | Switch panel |
| `Space` | Stage/unstage file |
| `a` | Stage all |
| `c` | Commit |
| `C` | Commit with editor |
| `P` | Push |
| `p` | Pull |
| `e` | Open file in editor |
| `o` | Open in browser |
| `/` | Search |
| `q` | Quit |

### Panels
1. **Status** — current branch, stash, merge state
2. **Files** — changed files
3. **Branches** — local branches
4. **Commits** — commit history
5. **Stash** — stashes

---

## gh-dash — GitHub Dashboard TUI
```bash
gh-dash               # open dashboard
```

**Shows:**
- Your open PRs
- Assigned issues
- Notifications
- GitHub Actions workflows

## Configuration
File: `modules/home/cli/git.nix`
