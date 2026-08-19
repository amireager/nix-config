# Amir's NixOS Workstation

A public, reproducible NixOS workstation configuration for an Acer Aspire A715-42G, built around Niri, Noctalia, Home Manager, isolated on-demand development environments, and a Bubblewrap sandbox.

This repository is not a generic NixOS starter. It is a real personal system with explicit hardware, network, security, desktop, editor, and development decisions. The structure is reusable, but host-specific values must be reviewed before deployment.

> The complete handbook is written in Persian: **[شروع مستندات فارسی](docs/README.md)**.

## What this repository owns

| Layer | Responsibility |
| --- | --- |
| Flake | Pins nixpkgs, Home Manager, Niri, Noctalia, Zen Browser, and nix-index-database |
| Host | Hardware configuration, bootloader, laptop policy, NVIDIA Prime offload, and keyboard remapping |
| NixOS modules | Nix/store policy, kernel and memory tuning, networking, DNS, security, desktop services, and Podman |
| Home Manager | Fish, terminals, CLI tools, GUI applications, XDG defaults, Niri configuration, Noctalia, and Neovim |
| Dev shells | Twelve language, build, media, networking, security, and AI environments realised only when requested |
| `dev` | Fast shell discovery, command execution, explicit profiles, and real indirect GC roots |
| `box` | Per-project Bubblewrap isolation with private Home/work storage and explicit host sharing |
| Documentation | Operational handbook, key reference, engineering rules, and architecture decision records |

## Architecture

```text
flake.nix
├── lib.mkHost
│   └── nixosConfigurations.nixos
│       ├── hosts/nixos
│       │   ├── hardware.nix
│       │   └── NixOS profiles
│       ├── users/amir/default.nix
│       └── Home Manager
│           └── users/amir/home.nix
│               └── modules/home/*
└── devShells.x86_64-linux
    └── shells/registry.nix
        └── shells/<name> → lib.mkDevShell
```

Home Manager is integrated as a NixOS module. A system rebuild therefore updates the operating system and the user environment as one generation.

Two values are intentionally shared across layers:

- `/etc/nixos` is the stable flake entry point. On the installed machine it is a symlink to the real Git checkout.
- `lib.proxy` owns the local SOCKS host and port used by proxychains, Fish helpers, Box, and session variables.

## Workstation highlights

### Niri and Noctalia

Niri provides a horizontally scrolling Wayland desktop. Noctalia supplies the bar, dock, launcher, control centre, notifications, wallpaper, lock screen, and graphical Polkit agent.

Idle timing is deliberately controlled through the Noctalia GUI rather than forced by Nix. This keeps Caffeine and temporary idle cancellation functional.

### Keyboard-first workflow

- CapsLock taps Escape and holds Super through keyd.
- Niri bindings cover application launch, columns, workspaces, media, screenshots, recording, and Noctalia IPC.
- Neovim uses Space as leader and exposes discoverable groups through which-key.
- Fish abbreviations expand before execution, so system-changing commands remain visible.

### On-demand development

```bash
dev                     # fast menu; no Flake evaluation
dev -i                  # select with FZF
dev python              # enter an interactive environment
dev rust cargo test     # run one command directly
dev --keep net          # realise and retain an environment
dev --roots             # inspect registration, generations, size, and last use
dev --prune             # confirm removal of stale or broken roots
```

Available environments:

| Environment | Focus |
| --- | --- |
| `agent` | Agent runtimes, AST search, web extraction, fast linters |
| `ai` | Local text, speech, image, RAG, and GPU tooling |
| `python` | Clean Python, uv, Ruff, Pyright, IPython |
| `rust` | Rust toolchain, rust-analyzer, cargo helpers, LLDB |
| `go` | Go, gopls, golangci-lint, Air, Delve |
| `web` | Node.js, Bun, pnpm, TypeScript, Biome, Tailwind |
| `build` | GCC, Clang, CMake, Ninja, GDB, LLDB |
| `cli` | Profiling, structured data, logs, processes, transfers |
| `media` | Full FFmpeg, image optimisation, OCR, PDF tools |
| `net` | Proxy cores, packet inspection, TLS and throughput diagnostics |
| `nix` | Packaging, source checks, review, search, closure analysis |
| `audit` | Secrets, CVEs, SBOMs, images, IaC, and system hardening |

Aliases: `dev c` → `build`, `dev data` → `python`, and `dev default` → `nix`.

### Box sandbox

`box` is installed globally rather than inside one dev shell, allowing it to inherit the exact tools of the calling environment.

```bash
box --dry-run --secure python suspicious.py
box --secure --net none command
box -s ~/.config/nvim -S ~/Downloads command
box -w ./explicit-project command
box --status
```

The invocation directory is never mounted automatically. Persistent mode uses `.box/work`; ephemeral mode uses tmpfs; `-w` is the only way to choose another host workspace.

### Security model

The target is a practical personal laptop, not a high-secrecy or theft-resistant platform:

- inbound firewall with no globally opened ports;
- sudo-rs with password-required wheel access;
- AppArmor and a medium-convenience USBGuard policy;
- firmware updates through fwupd;
- local DNSCrypt listener forced through `/etc/resolv.conf`;
- Box for untrusted execution;
- mutable password managed with `passwd`;
- no credentials or model files stored in the repository.

The user intentionally belongs to the `podman` group because rootful Podman access is used. Treat that group as privileged.

## Stable checkout path

The installed system expects the stable path `/etc/nixos`. Keep the editable repository elsewhere and point the stable path to it:

```bash
git clone https://github.com/amireager/nix-config "$HOME/nix-config"
sudo ln -sfn "$HOME/nix-config" /etc/nixos
readlink -f /etc/nixos
```

This lets scripts, `nh`, documentation, and recovery commands use one location even when the actual checkout moves.

## Before reusing this configuration

Review at least:

1. `hosts/nixos/hardware.nix` and the NVIDIA bus IDs;
2. hostname, username, home directory, timezone, and `stateVersion`;
3. bootloader and disk/filesystem declarations;
4. `/etc/nixos` symlink target;
5. local proxy and DNS assumptions;
6. unfree packages and binary caches;
7. Podman group membership and security policy;
8. hardware-specific power and kernel settings.

The template directories under `hosts/_template`, `users/_template`, and `shells/_template` document the expected extension points.

## Documentation map

| Guide | Subject |
| --- | --- |
| [Overview](docs/01-overview.md) | Flake flow, hosts, users, modules, and ownership |
| [Nix operations](docs/02-nix.md) | Build discipline, updates, closures, roots, cleanup, rollback |
| [Development](docs/03-dev.md) | `dev`, GC retention, direnv, and all twelve environments |
| [CLI handbook](docs/04-cli.md) | Fish and advanced recipes for search, data, HTTP, transfer, and diagnostics |
| [Desktop](docs/05-desktop.md) | Niri, Noctalia, Wayland services, and practical workflows |
| [Editor](docs/06-editor.md) | Neovim, LSP, DAP, REPL, Git, search, and AI |
| [AI](docs/07-ai.md) | Local inference, gateway flow, CodeCompanion, and token policy |
| [Sandbox](docs/08-sandbox.md) | Box storage, isolation boundaries, profiles, and audits |
| [Engineering rules](docs/09-rules.md) | Network constraints and repository extension rules |
| [Decisions](docs/10-decisions.md) | Architecture decision records and rejected alternatives |
| [Key reference](docs/keys.md) | Niri, Neovim, and shell shortcuts |

## Validation policy

The initial public CI is source-only. It checks formatting, static lint, secrets, Markdown/YAML, repository invariants, and shell syntax. It does not evaluate the Flake, build packages, activate a system, or start services.

Deployment and runtime validation remain explicit user actions because this repository targets real hardware.

## Contributing and security

- Read [CONTRIBUTING.md](CONTRIBUTING.md) before proposing structural changes.
- Use [SECURITY.md](SECURITY.md) for private vulnerability or credential reports.
- Never include real keys, tokens, passwords, age identities, private host data, or downloaded AI models.

## License

MIT — see [LICENSE](LICENSE).
