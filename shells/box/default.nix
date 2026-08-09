{
  mkDevShell,
  pkgs,
  ...
}:
# ==============================================================================
# BOX — Next-Gen Developer & AI Agent Sandbox (Home-Swap & Workspace Isolation)
# ==============================================================================
# A zero-overhead, ultra-fast sandboxing engine designed for:
#   1. Native Shebang & Path Compatibility: Mounts the workspace environment over
#      the real $HOME (/home/amir), so virtualenvs (.venv) and tools work natively.
#   2. Secret Protection: Host's ~/.ssh, ~/.aws, and tokens are completely hidden.
#   3. Flexible Workspace (-w): Switch working directory to /work or subprojects.
#   4. Multi-Path Sharing (-s): Mount host folders (e.g. -s ~/.config/nvim -s ~/.hermes -s ~/dl)
#      directly to matching sandbox paths in read-only or read-write mode.
#   5. Modifiers: Ephemeral RAM mode (-e), Zero-Net (-n), Proxy routing (-P), GPU (-g).
# ==============================================================================
let
  bwrap = "${pkgs.bubblewrap}/bin/bwrap";

  boxCli = pkgs.writeShellScriptBin "box" ''
    set -euo pipefail

    # ── Color Palette (Evaluated via printf for clean terminal display) ───────
    C_RESET="$(printf '\033[0m')"
    C_BOLD="$(printf '\033[1m')"
    C_CYAN="$(printf '\033[1;36m')"
    C_GREEN="$(printf '\033[1;32m')"
    C_YELLOW="$(printf '\033[1;33m')"
    C_RED="$(printf '\033[1;31m')"
    C_MAGENTA="$(printf '\033[1;35m')"
    C_DIM="$(printf '\033[1;30m')"

    print_help() {
      cat <<EOF
''${C_CYAN}''${C_BOLD}╔═══════════════════════════════════════════════════════════════════╗
║                   📦 BOX — Sandboxing Engine                      ║
╚═══════════════════════════════════════════════════════════════════╝''${C_RESET}

''${C_BOLD}USAGE:''${C_RESET}
  box [FLAGS] [COMMAND [ARGS...]]

''${C_BOLD}BEHAVIOR:''${C_RESET}
  • If no command is given, launches an interactive shell (''${SHELL:-fish}) inside the workspace.
  • Secrets (~/.ssh, ~/.aws) are isolated; Python & Hermes shebangs work natively.
  • Pass -s to share specific host configs or folders (e.g. -s ~/.hermes -s ~/.config/nvim).
  • Dev servers and Web UIs (e.g. localhost:3000) are fully accessible on the host.

''${C_BOLD}FLAGS & MODIFIERS:''${C_RESET}
  ''${C_YELLOW}-e, --ephemeral, --tmp''${C_RESET}     Pure RAM mode (tmpfs). Everything vanishes upon exit.
  ''${C_YELLOW}-n, --offline, --no-net''${C_RESET}    Completely cut off network access (Zero-Net).
  ''${C_YELLOW}-P, --proxy [PORT]''${C_RESET}         Route all traffic through SOCKS5 proxy (default: 1819).
  ''${C_YELLOW}-g, --gpu''${C_RESET}                  Grant access to Nvidia GPU and CUDA devices.
  ''${C_YELLOW}-s, --share <PATH>''${C_RESET}        Share host path (repeatable, e.g. -s ~/.hermes -s ~/.config/nvim).
  ''${C_YELLOW}-w, --workdir <DIR>''${C_RESET}        Use custom directory/subproject as workspace.
  ''${C_YELLOW}--clean''${C_RESET}                    Wipe the persistent sandbox storage for this workspace.
  ''${C_YELLOW}--inspect <CMD>''${C_RESET}            Trace file and network calls with strace.
  ''${C_YELLOW}-h, --help''${C_RESET}                 Show this help manual.

''${C_BOLD}EXAMPLES:''${C_RESET}
  ''${C_DIM}# 1. Interactive sandbox shell in current folder''${C_RESET}
  box

  ''${C_DIM}# 2. Run Hermes in sandbox with its configuration shared''${C_RESET}
  box -s ~/.hermes hermes

  ''${C_DIM}# 3. Work on a subproject folder mounted at /work''${C_RESET}
  box -w work/

  ''${C_DIM}# 4. Test untrusted script in RAM (zero traces on disk)''${C_RESET}
  box -e curl -sSL https://example.com/install.sh | bash

  ''${C_DIM}# 5. Isolated offline build/test''${C_RESET}
  box -n npm test

  ''${C_DIM}# 6. Run AI model or PyTorch with Nvidia GPU acceleration''${C_RESET}
  box -g python train.py

  ''${C_DIM}# 7. Force traffic through local proxy''${C_RESET}
  box -P 1819 aichat "Explain this repo"
EOF
    }

    # ── Default Options ──────────────────────────────────────────────────────
    OPT_EPHEMERAL=0
    OPT_OFFLINE=0
    OPT_GPU=0
    OPT_PROXY=""
    OPT_SHARES=()
    OPT_WORKDIR="$PWD"
    OPT_INSPECT=0
    CMD=()
    REAL_HOST_HOME="''${HOME:-/home/''${USER:-user}}"
    REAL_USER="''${USER:-user}"

    # ── Parse Command Line Flags ─────────────────────────────────────────────
    while [ $# -gt 0 ]; do
      case "$1" in
        -h|--help)
          print_help
          exit 0
          ;;
        --clean)
          TARGET_STORAGE="''${REAL_HOST_HOME}/.local/share/box/workspaces/$(basename "$PWD")"
          if [ -d "$TARGET_STORAGE" ]; then
            printf "''${C_YELLOW}Remove sandbox storage in %s? [y/N] ''${C_RESET}" "$TARGET_STORAGE"
            read -r reply
            case "$reply" in
              [yY]*)
                rm -rf "$TARGET_STORAGE"
                echo -e "''${C_GREEN}✔ Sandbox storage cleaned successfully.''${C_RESET}"
                exit 0
                ;;
              *)
                echo "Cancelled."
                exit 0
                ;;
            esac
          else
            echo "No persistent sandbox storage found for $PWD."
            exit 0
          fi
          ;;
        -e|--ephemeral|--tmp)
          OPT_EPHEMERAL=1
          shift
          ;;
        -n|--offline|--no-net)
          OPT_OFFLINE=1
          shift
          ;;
        -g|--gpu)
          OPT_GPU=1
          shift
          ;;
        -P|--proxy)
          if [ $# -ge 2 ] && [[ "$2" =~ ^[0-9]+$ ]]; then
            OPT_PROXY="$2"
            shift 2
          else
            OPT_PROXY="1819"
            shift
          fi
          ;;
        -s|--share)
          [ $# -ge 2 ] || { echo -e "''${C_RED}box: -s/--share requires a path argument''${C_RESET}" >&2; exit 1; }
          OPT_SHARES+=("$2")
          shift 2
          ;;
        -w|--workdir|-p|--path)
          [ $# -ge 2 ] || { echo -e "''${C_RED}box: $1 requires a path argument''${C_RESET}" >&2; exit 1; }
          OPT_WORKDIR="$(cd "$2" && pwd -P)"
          shift 2
          ;;
        --inspect)
          OPT_INSPECT=1
          shift
          ;;
        --)
          shift
          CMD+=("$@")
          break
          ;;
        *)
          CMD+=("$@")
          break
          ;;
      esac
    done

    # ── Workspace and Storage Layout ─────────────────────────────────────────
    HOST_WORK="$OPT_WORKDIR"
    PROJECT_ROOT="$PWD"
    WORKSPACE_NAME="$(basename "$PROJECT_ROOT")"
    CENTRAL_BOX="''${REAL_HOST_HOME}/.local/share/box/workspaces/''${WORKSPACE_NAME}"
    HOST_HOME="''${CENTRAL_BOX}/home"

    if [ "$OPT_EPHEMERAL" -eq 0 ]; then
      mkdir -p "$HOST_HOME"/{.config,.cache,.local/bin,.local/share,.npm-global/bin,.cargo/bin,go/bin}
    fi

    # ── Build bwrap Arguments ────────────────────────────────────────────────
    # 1. Mount root filesystem, /proc, /dev, /tmp
    # 2. Set TMPDIR to /tmp to prevent stale host temp directory errors
    # 3. Swap $REAL_HOST_HOME with isolated home storage
    BWRAP_ARGS=(
      --die-with-parent
      --unshare-user
      --unshare-ipc
      --unshare-pid
      --unshare-uts
      --unshare-cgroup-try
      --proc /proc
      --dev /dev
      --ro-bind /nix /nix
      --ro-bind /usr /usr
      --ro-bind /bin /bin
      --ro-bind-try /lib /lib
      --ro-bind-try /lib64 /lib64
      --ro-bind /etc /etc
      --ro-bind-try /run /run
      --ro-bind-try /var /var
      --tmpfs /tmp
      --dir /tmp/xdg-runtime
      --tmpfs "$REAL_HOST_HOME"
    )

    # Network configuration
    if [ "$OPT_OFFLINE" -eq 1 ]; then
      BWRAP_ARGS+=(--unshare-net)
    else
      BWRAP_ARGS+=(--share-net)
    fi

    # Home-Swap: Mount sandbox profile over $REAL_HOST_HOME
    if [ "$OPT_EPHEMERAL" -eq 1 ]; then
      BWRAP_ARGS+=(--tmpfs "$REAL_HOST_HOME")
    else
      BWRAP_ARGS+=(--bind "$HOST_HOME" "$REAL_HOST_HOME")
    fi

    # Bind the parent project root so real paths and .venv resolve seamlessly
    BWRAP_ARGS+=(
      --dir "$PROJECT_ROOT"
      --bind "$PROJECT_ROOT" "$PROJECT_ROOT"
    )

    # If -w specified a subfolder, also mount /work pointing to it
    if [ "$HOST_WORK" != "$PROJECT_ROOT" ]; then
      BWRAP_ARGS+=(
        --dir "$HOST_WORK"
        --bind "$HOST_WORK" "$HOST_WORK"
        --dir /work
        --bind "$HOST_WORK" /work
      )
    else
      BWRAP_ARGS+=(
        --dir /work
        --bind "$PROJECT_ROOT" /work
      )
    fi

    # Shell Environment Integration: bind host fish config into sandbox home (read-only)
    if [ -d "''${REAL_HOST_HOME}/.config/fish" ]; then
      BWRAP_ARGS+=(--ro-bind-try "''${REAL_HOST_HOME}/.config/fish" "''${REAL_HOST_HOME}/.config/fish")
    fi
    if [ -f "''${REAL_HOST_HOME}/.config/starship.toml" ]; then
      BWRAP_ARGS+=(--ro-bind-try "''${REAL_HOST_HOME}/.config/starship.toml" "''${REAL_HOST_HOME}/.config/starship.toml")
    fi

    # Auto-share ~/.hermes if present on host unless explicitly omitted
    if [ -d "''${REAL_HOST_HOME}/.hermes" ]; then
      BWRAP_ARGS+=(--bind-try "''${REAL_HOST_HOME}/.hermes" "''${REAL_HOST_HOME}/.hermes")
    fi

    # GPU Hardware Passthrough
    if [ "$OPT_GPU" -eq 1 ]; then
      for dev in /dev/nvidia* /dev/dri /dev/vga_arbiter; do
        if [ -e "$dev" ]; then
          BWRAP_ARGS+=(--dev-bind "$dev" "$dev")
        fi
      done
    fi

    # ── Multi-Path Sharing Logic (-s / --share) ──────────────────────────────
    for entry in "''${OPT_SHARES[@]+''${OPT_SHARES[@]}}"; do
      [ -n "$entry" ] || continue
      src=""
      dst=""
      mode="--ro-bind-try"

      if [[ "$entry" == *":"* ]]; then
        p1=""
        p2=""
        p3=""
        IFS=":" read -r p1 p2 p3 <<< "$entry"
        src="$p1"
        if [ "$p2" = "rw" ] || [ "$p2" = "ro" ]; then
          [ "$p2" = "rw" ] && mode="--bind-try"
        else
          dst="$p2"
          [ "$p3" = "rw" ] && mode="--bind-try"
        fi
      else
        src="$entry"
      fi

      # Expand tilde
      src="''${src/#\~/$REAL_HOST_HOME}"
      if [ -e "$src" ]; then
        src="$(cd "$(dirname "$src")" && pwd -P)/$(basename "$src")"
        if [ -z "$dst" ]; then
          dst="$src"
        else
          dst="''${dst/#\~/$REAL_HOST_HOME}"
        fi
        BWRAP_ARGS+=("$mode" "$src" "$dst")
      fi
    done

    # Working Directory inside sandbox
    BWRAP_ARGS+=(--chdir "$HOST_WORK")

    # ── Assemble Clean PATH inside sandbox ───────────────────────────────────
    # Ensure project .venv and host local bins are prioritized
    SANDBOX_PATH="''${PROJECT_ROOT}/.venv/bin:''${HOST_WORK}/.venv/bin:''${REAL_HOST_HOME}/.local/bin:''${REAL_HOST_HOME}/.npm-global/bin:''${REAL_HOST_HOME}/.cargo/bin:$PATH"

    # ── Sandbox Environment Variables ────────────────────────────────────────
    ENV_ARGS=(
      --setenv USER "$REAL_USER"
      --setenv LOGNAME "$REAL_USER"
      --setenv HOME "$REAL_HOST_HOME"
      --setenv PWD "$HOST_WORK"
      --setenv TMPDIR "/tmp"
      --setenv TMP "/tmp"
      --setenv TEMP "/tmp"
      --setenv TERM "''${TERM:-xterm-256color}"
      --setenv COLORTERM "''${COLORTERM:-truecolor}"
      --setenv LANG "''${LANG:-C.UTF-8}"
      --setenv XDG_CONFIG_HOME "$REAL_HOST_HOME/.config"
      --setenv XDG_CACHE_HOME "$REAL_HOST_HOME/.cache"
      --setenv XDG_DATA_HOME "$REAL_HOST_HOME/.local/share"
      --setenv XDG_RUNTIME_DIR "/tmp/xdg-runtime"
      --setenv npm_config_prefix "$REAL_HOST_HOME/.npm-global"
      --setenv PIP_PREFIX "$REAL_HOST_HOME/.local"
      --setenv CARGO_HOME "$REAL_HOST_HOME/.cargo"
      --setenv GOPATH "$REAL_HOST_HOME/go"
      --setenv PATH "$SANDBOX_PATH"
      --setenv HERMES_HOME "$REAL_HOST_HOME/.hermes"
      --setenv BOX_ACTIVE "1"
    )

    # Dynamic library & nix-ld passthrough for pre-compiled / downloaded binaries
    [ -n "''${NIX_LD:-}" ] && ENV_ARGS+=(--setenv NIX_LD "$NIX_LD")
    [ -n "''${NIX_LD_LIBRARY_PATH:-}" ] && ENV_ARGS+=(--setenv NIX_LD_LIBRARY_PATH "$NIX_LD_LIBRARY_PATH")

    # Proxy Routing
    if [ -n "$OPT_PROXY" ]; then
      PROXY_URL="socks5h://127.0.0.1:$OPT_PROXY"
      ENV_ARGS+=(
        --setenv ALL_PROXY "$PROXY_URL"
        --setenv HTTP_PROXY "$PROXY_URL"
        --setenv HTTPS_PROXY "$PROXY_URL"
        --setenv all_proxy "$PROXY_URL"
        --setenv http_proxy "$PROXY_URL"
        --setenv https_proxy "$PROXY_URL"
        --setenv SOCKS5_SERVER "127.0.0.1:$OPT_PROXY"
      )
    fi

    # ── Determine Target Command ─────────────────────────────────────────────
    if [ ''${#CMD[@]} -eq 0 ]; then
      if command -v fish >/dev/null 2>&1; then
        TARGET_CMD=(fish)
      else
        TARGET_CMD=(bash)
      fi
    else
      TARGET_CMD=("''${CMD[@]}")
    fi

    # ── Execution ────────────────────────────────────────────────────────────
    if [ "$OPT_INSPECT" -eq 1 ]; then
      echo -e "''${C_MAGENTA}🔍 [box inspect] Monitoring filesystem access with strace...''${C_RESET}"
      exec ${pkgs.strace}/bin/strace -f -e trace=file ${bwrap} "''${BWRAP_ARGS[@]}" "''${ENV_ARGS[@]}" -- "''${TARGET_CMD[@]}"
    else
      exec ${bwrap} "''${BWRAP_ARGS[@]}" "''${ENV_ARGS[@]}" -- "''${TARGET_CMD[@]}"
    fi
  '';
in
  mkDevShell {
    name = "box";
    icon = "📦";
    description = "Next-Gen Sandbox: Home-Swap, Python Shebang Safety, Multi-Share (-s), Ephemeral RAM & GPU";

    packages = [
      boxCli
      pkgs.bubblewrap
      pkgs.strace
      pkgs.lsof
    ];

    tips = [
      {
        key = "Interactive";
        cmd = "box                 (launches isolated shell in workspace)";
      }
      {
        key = "Share Host Configs";
        cmd = "box -s ~/.config/nvim -s ~/.hermes";
      }
      {
        key = "Subproject";
        cmd = "box -w work/        (work in subproject with parent .venv available)";
      }
      {
        key = "Ephemeral RAM";
        cmd = "box -e <cmd>        (pure memory tmpfs, zero disk trace)";
      }
      {
        key = "Zero-Net";
        cmd = "box -n <cmd>        (isolated network stack)";
      }
      {
        key = "GPU / CUDA";
        cmd = "box -g <cmd>        (Nvidia GTX 1650 & CUDA passthrough)";
      }
      {
        key = "Proxy Route";
        cmd = "box -P 1819 <cmd>   (route all traffic through local proxy)";
      }
      {
        key = "Inspect";
        cmd = "box --inspect <cmd> (trace touched paths with strace)";
      }
      {
        key = "Clean Storage";
        cmd = "box --clean         (wipe workspace sandbox storage)";
      }
    ];

    notes = [
      "Home-Swap: Isolated home mounted over real path (Python Shebangs work natively)"
      "Clean Workdir: Persistent storage lives in ~/.local/share/box/workspaces/"
      "Local Tools: npm -g, pip, cargo, and curl | bash install cleanly into sandbox"
      "Ports Open: Web UIs & dev servers on localhost/0.0.0.0 reach the host browser"
    ];
  }
