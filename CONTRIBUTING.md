# Contributing

This is a personal workstation configuration deployed on real hardware. Contributions are welcome when they preserve the repository's explicit ownership boundaries and do not add daily workflow friction.

## Principles

1. Keep host hardware in `hosts/`, NixOS policy in `modules/nixos/`, and user configuration in `modules/home/`.
2. Keep frequently used tools global; place heavy or project-specific tools in the matching dev shell.
3. Do not add a second source of truth for shell names, proxy settings, shortcuts, or package ownership.
4. Preserve Box's private `.box/work` default. The invocation directory must never be mounted implicitly.
5. Keep Noctalia idle timing GUI-managed so Caffeine remains effective.
6. Never add credentials, passwords, private keys, age identities, model files, or machine-private data.
7. Prefer a small explicit module over a framework or abstraction that has only one caller.
8. Explain operationally surprising decisions in `docs/10-decisions.md`.

## Change workflow

1. Read the relevant guide under `docs/` and inspect the current source owner.
2. Make one logically scoped change.
3. Update documentation and completion definitions in the same change.
4. Run source-only checks before proposing deployment.
5. Review the diff for generated paths, secrets, accidental file-mode changes, and stale comments.
6. Build or activate only on an intended NixOS test machine.

## Source-only checks

CI gates full Flake evaluation plus formatting and lint. `dev nix nix-check` is the local mirror of the exact CI sequence; additional local checks include:

```bash
git diff --check
bash -n modules/home/dev/box/box.sh
alejandra --check .
statix check .
deadnix --fail .
stylua --check modules/home/dev/nvim/lua
```

Some commands may be unavailable outside a Nix environment. Use `dev nix` for the Nix-focused tools. Do not treat a static check as proof that a NixOS generation boots or that desktop services start.

## Adding a host

1. Copy `hosts/_template` to `hosts/<hostname>`.
2. replace `hardware.nix` with output from the target machine;
3. select only the profiles supported by that hardware;
4. set bootloader and `system.stateVersion` in the host;
5. add a `nixosConfigurations.<hostname>` entry in `flake.nix`.

Do not copy NVIDIA bus IDs, filesystems, kernel modules, or bootloader settings blindly.

## Adding a user

1. Copy `users/_template` to `users/<username>`.
2. Set the NixOS user, primary group, shell, home path, and Home Manager state version.
3. Register the user in the corresponding `lib.mkHost` call.
4. Import only Home Manager modules that user actually needs.

## Adding a dev shell

1. Copy `shells/_template` to `shells/<name>`.
2. Keep the shell declarative: packages, environment, tips, notes, and guarded hooks.
3. Add the name to `shells/registry.nix` and exactly one display group.
4. Add aliases only when they are stable and unambiguous.
5. Update `docs/03-dev.md` and any relevant completion/consistency checks.

A shell must not start a service, download a model, or modify the project merely by being entered.

## Commit style

Use focused imperative subjects with a conventional prefix when useful:

```text
fix(box): reject invalid explicit proxy ports
refactor(dev): separate root handling from completions
docs(cli): add structured search and transfer recipes
ci: add source-only secret and syntax checks
```

Avoid mixing unrelated desktop, network, editor, and documentation changes in one commit.
