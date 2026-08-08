{
  mkDevShell,
  pkgs,
  ...
}:
# ==============================================================================
# BOX — run tools without handing them your home directory
# ==============================================================================
# Three problems, one mechanism:
#
#   1. Safety   — run unaudited programs without exposing ~/.ssh, ~/.aws,
#                 tokens, or other agents' credentials.
#   2. Tidiness — agents scatter config/cache/state across the home directory.
#                 Confine each one to a profile folder instead.
#   3. Identity — every agent gets its OWN home, so `mimo` cannot read
#                 opencode's auth.json. (Observed in practice: mimo touches
#                 ~/.local/share/opencode/auth.json and ~/.claude/projects.)
#
# All three are solved by building a mount namespace where the paths we did not
# allow SIMPLY DO NOT EXIST. This is the difference from an env-var approach
# (XDG_CONFIG_HOME=…): there the tool can still read $HOME and write anywhere.
# Here the syscall returns ENOENT because there is nothing to open.
#
# ── The home-swap trick ───────────────────────────────────────────────────
# The profile directory is bind-mounted AT the real home path (/home/$USER),
# not merely pointed at by $HOME. Many tools ignore the environment variable
# and call getpwuid(getuid())->pw_dir instead; mounting over the real path
# covers both. Inside the box, /home/$USER exists and is writable, but its
# contents are the profile — the real home is not in the namespace at all.
#
# ── Two strictness levels ─────────────────────────────────────────────────
# `box run`  — allowlist: only /nix/store plus a few /etc files. Maximum
#              containment, but shell scripts with #!/bin/bash and downloaded
#              binaries fail, because /bin and /run/current-system are absent.
# `box dev`  — the whole system read-only, home swapped. Scripts and
#              pre-built binaries work (nix-ld is wired through), the system
#              cannot be modified, and the real home is still invisible.
#              This is the `fj` replacement.
#
# ── Honest limits ─────────────────────────────────────────────────────────
# bwrap shares the host kernel. Right tool for "software I have not audited"
# and for "stop this thing littering my home". NOT a boundary against
# deliberate malware — a kernel exploit escapes it. Use `box vm` for that.
# ==============================================================================
let
  # ── Shared runtime helpers ────────────────────────────────────────────────
  # Kept in one place so policy cannot drift between subcommands.
  common = ''
    _box_die() { printf 'box: %s\n' "$1" >&2; exit 1; }

    # Project root: nearest ancestor containing .box/, else $PWD.
    _box_root() {
      local d="$PWD"
      while [ "$d" != "/" ]; do
        [ -d "$d/.box" ] && { printf '%s' "$d"; return; }
        d="$(dirname "$d")"
      done
      printf '%s' "$PWD"
    }

    # Profiles are per-project and there may be several, so a single task can
    # keep e.g. `agent-a` and `agent-b` completely separate.
    _box_init() {
      BOX_PROFILE="''${1:-default}"
      BOX_ROOT="$(_box_root)"
      BOX_DIR="$BOX_ROOT/.box"
      BOX_HOME="$BOX_DIR/profiles/$BOX_PROFILE"
      BOX_REAL_HOME="''${HOME:-/home/$USER}"

      mkdir -p "$BOX_HOME"/.{config,cache,local/share,local/state}
      [ -f "$BOX_DIR/.gitignore" ] || printf '*\n' > "$BOX_DIR/.gitignore"
    }

    # Environment every box gets. Deliberately minimal: no SSH_AUTH_SOCK, no
    # API keys, no GPG agent — if a tool needs a secret it must be placed in
    # the profile explicitly.
    _box_env() {
      BOX_ENV=(
        --setenv HOME "$BOX_REAL_HOME"
        --setenv USER "''${USER:-user}"
        --setenv LOGNAME "''${USER:-user}"
        --setenv SHELL "''${SHELL:-/bin/sh}"
        --setenv PATH "$PATH"
        --setenv TERM "''${TERM:-xterm-256color}"
        --setenv COLORTERM "''${COLORTERM:-truecolor}"
        --setenv LANG "''${LANG:-C.UTF-8}"
        --setenv XDG_CONFIG_HOME "$BOX_REAL_HOME/.config"
        --setenv XDG_CACHE_HOME "$BOX_REAL_HOME/.cache"
        --setenv XDG_DATA_HOME "$BOX_REAL_HOME/.local/share"
        --setenv XDG_STATE_HOME "$BOX_REAL_HOME/.local/state"
        --setenv XDG_RUNTIME_DIR "/tmp/xdg-runtime"
        --setenv BOX_ACTIVE "1"
        --setenv BOX_PROFILE "$BOX_PROFILE"
      )

      # nix-ld makes downloaded, non-Nix binaries runnable. Without these two
      # variables such a binary cannot even start on NixOS.
      [ -n "''${NIX_LD:-}" ] && BOX_ENV+=(--setenv NIX_LD "$NIX_LD")
      [ -n "''${NIX_LD_LIBRARY_PATH:-}" ] &&
        BOX_ENV+=(--setenv NIX_LD_LIBRARY_PATH "$NIX_LD_LIBRARY_PATH")
    }

    # Mount layout shared by run/dev: profile over the real home, project
    # read-write, a private /tmp.
    _box_mounts() {
      BOX_MOUNTS=(
        --die-with-parent
        --unshare-user
        --unshare-ipc
        --unshare-pid
        --unshare-uts
        --unshare-cgroup-try
        --proc /proc
        --dev /dev
        --tmpfs /tmp
        --dir /tmp/xdg-runtime
        --tmpfs "$BOX_REAL_HOME"
        --bind "$BOX_HOME" "$BOX_REAL_HOME"
        --bind "$BOX_ROOT" "$BOX_ROOT"
        --chdir "$PWD"
      )
    }

    # NOTE ON --new-session
    # bwrap's --new-session calls setsid(), which detaches the sandbox from the
    # controlling terminal. That blocks TIOCSTI keystroke injection, but it
    # also breaks every interactive TUI: fish refuses to start ("No TTY for
    # interactive shell"), and agent chat interfaces never draw.
    # We therefore omit it for interactive use and rely on the kernel instead:
    # TIOCSTI is disabled by default since Linux 6.2. Verify with
    #   sysctl dev.tty.legacy_tiocsti      # expect 0
    # and see modules/nixos/security.nix, which pins it explicitly.
    # Non-interactive invocations (`box exec`) still get --new-session.
  '';

  bwrap = "${pkgs.bubblewrap}/bin/bwrap";

  # ── box dev — system visible read-only, home swapped ──────────────────────
  boxDev = pkgs.writeShellScriptBin "box-dev" ''
    set -eu
    ${common}
    _box_init "''${BOX_PROFILE_NAME:-default}"
    [ $# -gt 0 ] || _box_die "usage: box dev [-p profile] <command> [args...]"
    _box_env
    _box_mounts

    # Whole system read-only. This is what makes #!/bin/bash scripts and
    # downloaded binaries work, unlike the allowlist in `box run`.
    exec ${bwrap} \
      "''${BOX_MOUNTS[@]}" "''${BOX_ENV[@]}" \
      --ro-bind / / \
      --tmpfs "$BOX_REAL_HOME" \
      --bind "$BOX_HOME" "$BOX_REAL_HOME" \
      --bind "$BOX_ROOT" "$BOX_ROOT" \
      --tmpfs /tmp \
      --dir /tmp/xdg-runtime \
      --proc /proc \
      --dev /dev \
      --share-net \
      -- "$@"
  '';

  # ── box run — strict allowlist ────────────────────────────────────────────
  boxRun = pkgs.writeShellScriptBin "box-run" ''
    set -eu
    ${common}
    _box_init "''${BOX_PROFILE_NAME:-default}"
    [ $# -gt 0 ] || _box_die "usage: box run [-p profile] <command> [args...]"
    _box_env
    _box_mounts

    exec ${bwrap} \
      "''${BOX_MOUNTS[@]}" "''${BOX_ENV[@]}" \
      --ro-bind /nix/store /nix/store \
      --ro-bind-try /etc/ssl /etc/ssl \
      --ro-bind-try /etc/static/ssl /etc/static/ssl \
      --ro-bind-try /etc/ssl/certs /etc/ssl/certs \
      --ro-bind-try /etc/resolv.conf /etc/resolv.conf \
      --ro-bind-try /etc/hosts /etc/hosts \
      --ro-bind-try /etc/localtime /etc/localtime \
      --ro-bind-try /etc/zoneinfo /etc/zoneinfo \
      --share-net \
      -- "$@"
  '';

  # ── box offline — like dev, but no network ────────────────────────────────
  boxOffline = pkgs.writeShellScriptBin "box-offline" ''
    set -eu
    ${common}
    _box_init "''${BOX_PROFILE_NAME:-default}"
    [ $# -gt 0 ] || _box_die "usage: box net [-p profile] <command> [args...]"
    _box_env
    _box_mounts

    exec ${bwrap} \
      "''${BOX_MOUNTS[@]}" "''${BOX_ENV[@]}" \
      --unshare-net \
      --ro-bind / / \
      --tmpfs "$BOX_REAL_HOME" \
      --bind "$BOX_HOME" "$BOX_REAL_HOME" \
      --bind "$BOX_ROOT" "$BOX_ROOT" \
      --tmpfs /tmp \
      --dir /tmp/xdg-runtime \
      --proc /proc \
      --dev /dev \
      -- "$@"
  '';

  # ── box exec — non-interactive, with --new-session ────────────────────────
  # Safe to harden fully because nothing needs a controlling terminal.
  boxExec = pkgs.writeShellScriptBin "box-exec" ''
    set -eu
    ${common}
    _box_init "''${BOX_PROFILE_NAME:-default}"
    [ $# -gt 0 ] || _box_die "usage: box exec [-p profile] <command> [args...]"
    _box_env
    _box_mounts

    exec ${bwrap} \
      "''${BOX_MOUNTS[@]}" "''${BOX_ENV[@]}" \
      --new-session \
      --ro-bind / / \
      --tmpfs "$BOX_REAL_HOME" \
      --bind "$BOX_HOME" "$BOX_REAL_HOME" \
      --bind "$BOX_ROOT" "$BOX_ROOT" \
      --tmpfs /tmp \
      --dir /tmp/xdg-runtime \
      --proc /proc \
      --dev /dev \
      --share-net \
      -- "$@"
  '';

  # ── box vm — podman, separate root and kernel surface ─────────────────────
  boxVm = pkgs.writeShellScriptBin "box-vm" ''
    set -eu
    ${common}
    _box_init "''${BOX_PROFILE_NAME:-default}"
    [ $# -gt 0 ] || _box_die "usage: box vm [-p profile] <command> [args...]"

    IMG="''${BOX_IMAGE:-docker.io/library/debian:stable-slim}"
    exec ${pkgs.podman}/bin/podman run --rm -it \
      --userns=keep-id \
      --security-opt no-new-privileges \
      --cap-drop=ALL \
      -v "$BOX_ROOT":/work:rw \
      -v "$BOX_HOME":/root:rw \
      -w /work \
      "$IMG" "$@"
  '';

  # ── box limit — resource ceiling, orthogonal to isolation ─────────────────
  boxLimit = pkgs.writeShellScriptBin "box-limit" ''
    set -eu
    MEM="''${BOX_MEM:-4G}"
    CPU="''${BOX_CPU:-200%}"
    [ $# -gt 0 ] || { echo "usage: box limit <command> [args...]" >&2; exit 1; }
    exec systemd-run --user --scope --quiet \
      -p MemoryMax="$MEM" -p CPUQuota="$CPU" -- "$@"
  '';

  # ── box inspect — evidence instead of guesswork ───────────────────────────
  boxInspect = pkgs.writeShellScriptBin "box-inspect" ''
    set -eu
    [ $# -gt 0 ] || { echo "usage: box inspect <command> [args...]" >&2; exit 1; }
    LOG="$(mktemp)"
    ${pkgs.strace}/bin/strace -f -e trace=file -o "$LOG" "$@" >/dev/null 2>&1 || true
    echo "Paths touched outside the project:"
    grep -oE '"[^"]+"' "$LOG" \
      | tr -d '"' \
      | grep -E "^($HOME|/etc|/var)" \
      | grep -v "^$PWD" \
      | sort -u \
      | head -60
    rm -f "$LOG"
  '';

  box = pkgs.writeShellScriptBin "box" ''
        set -eu

        # -p/--profile selects which profile directory to use, so one project can
        # hold several independent identities. Accepted before OR after the
        # subcommand, because both read naturally:
        #   box -p work dev hermes chat
        #   box dev -p work hermes chat
        PROFILE="default"
        CMD=""
        ARGS=()
        while [ $# -gt 0 ]; do
          case "$1" in
            -p | --profile)
              [ $# -ge 2 ] || { printf 'box: %s needs a profile name\n' "$1" >&2; exit 1; }
              PROFILE="$2"
              shift 2
              ;;
            *)
              if [ -z "$CMD" ]; then
                CMD="$1"
                shift
              else
                # Everything after the subcommand belongs to the child command;
                # stop parsing so `box dev foo -p bar` passes -p through.
                ARGS+=("$@")
                break
              fi
              ;;
          esac
        done
        set -- ''${ARGS[@]+"''${ARGS[@]}"}
        export BOX_PROFILE_NAME="$PROFILE"

        case "$CMD" in
          dev)     exec ${boxDev}/bin/box-dev "$@" ;;
          run)     exec ${boxRun}/bin/box-run "$@" ;;
          net)     exec ${boxOffline}/bin/box-offline "$@" ;;
          exec)    exec ${boxExec}/bin/box-exec "$@" ;;
          vm)      exec ${boxVm}/bin/box-vm "$@" ;;
          limit)   exec ${boxLimit}/bin/box-limit "$@" ;;
          inspect) exec ${boxInspect}/bin/box-inspect "$@" ;;
          shell)   exec ${boxDev}/bin/box-dev ${pkgs.fish}/bin/fish ;;

          ls)
            if [ -d .box/profiles ]; then
              for p in .box/profiles/*/; do
                [ -d "$p" ] || continue
                printf '  %-20s %s\n' "$(basename "$p")" "$(du -sh "$p" 2>/dev/null | cut -f1)"
              done
            else
              echo "  (no profiles yet in $PWD)"
            fi
            ;;

          clean)
            [ -d .box ] || { echo "box: nothing to clean"; exit 0; }
            if [ "$PROFILE" != "default" ]; then
              printf 'Remove profile %s? [y/N] ' "$PROFILE"
              read -r a
              case "$a" in [yY]*) rm -rf ".box/profiles/$PROFILE" && echo removed ;; *) echo kept ;; esac
            else
              printf 'Remove ALL of %s/.box? [y/N] ' "$PWD"
              read -r a
              case "$a" in [yY]*) rm -rf .box && echo removed ;; *) echo kept ;; esac
            fi
            ;;

          *)
            cat <<'USAGE'
    box — run tools without handing them your home directory

      box dev     <cmd>   system read-only, home swapped   ← default choice
      box run     <cmd>   strict allowlist (/nix/store only)
      box net     <cmd>   like dev, no network
      box exec    <cmd>   non-interactive, fully hardened
      box vm      <cmd>   podman: separate root, caps dropped
      box shell           interactive fish inside a box
      box limit   <cmd>   cap memory/CPU (BOX_MEM=4G BOX_CPU=200%)
      box inspect <cmd>   trace which paths a tool really needs
      box ls              list this project's profiles
      box clean           delete a profile, or all of .box

      -p <name>           pick a profile (default: "default")

    Each profile is a separate home at ./.box/profiles/<name>/, mounted over
    the real home path inside the box. Two profiles never see each other, so
    one agent cannot read another's credentials.

      box -p work  dev  hermes chat
      box -p test  dev  hermes chat      # independent identity

    dev vs run: `dev` exposes the system read-only so #!/bin/bash scripts and
    downloaded binaries work. `run` shows only /nix/store — stricter, but most
    scripts will not start.
    USAGE
            ;;
        esac
  '';
in
  mkDevShell {
    name = "box";
    icon = "📦";
    description = "Run agents and tools with a swapped-out home";

    packages = [
      box
      pkgs.bubblewrap
      pkgs.podman
      pkgs.strace
      pkgs.lsof
    ];

    tips = [
      {
        key = "Usual case";
        cmd = "box dev <cmd>";
      }
      {
        key = "Named profile";
        cmd = "box -p work dev <cmd>";
      }
      {
        key = "Strictest";
        cmd = "box run <cmd>  /  box net <cmd>";
      }
      {
        key = "Explore";
        cmd = "box shell";
      }
      {
        key = "Learn needs";
        cmd = "box inspect <cmd>";
      }
      {
        key = "Profiles";
        cmd = "box ls  /  box -p x clean";
      }
    ];

    notes = [
      "Profiles live in ./.box/profiles/<name>/ and are mounted over \\$HOME"
      "dev = system read-only (scripts work) · run = /nix/store only (strict)"
      "bwrap shares the host kernel: good for unaudited tools, not for malware"
    ];
  }
