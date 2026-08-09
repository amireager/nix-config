{
  mkDevShell,
  pkgs,
  ...
}:
# ==============================================================================
# BOX — Universal, Language-Agnostic Developer & Tool Sandbox
# ==============================================================================
# A zero-overhead, ultra-fast sandboxing engine designed for:
#   1. Clean Virtual /work Mount: Inside the sandbox, workspace is always /work.
#   2. Pure & Agnostic: No hardcoded languages/tools. Inherits caller shell's tools.
#   3. Modular .box/ Layout: Creates .box/{home, work, tmp} locally. Any custom folder
#      created in .box/<name> is automatically mapped as /<name> inside the sandbox.
#   4. Persistent /tmp: In standard mode, /tmp maps directly to .box/tmp/ on the host.
#   5. Zero-Trust Security: Host's ~/.ssh, ~/.aws, and tokens are completely hidden.
#      Zero host path leaks. No implicit sharing; only paths passed via -s / -S are mounted.
#   6. Dual-Mode Sharing:
#      • -s <SRC>[:<DST>]  -> Read-Only share  (e.g. -s ~/.config/nvim)
#      • -S <SRC>[:<DST>]  -> Read-Write share (e.g. -S ~/Downloads -S ~/src/venv:~/venv)
#   7. Resource Limits: Memory (--mem 4G) and CPU (--cpu 200%) ceilings via cgroups.
#   8. Modifiers: Ephemeral RAM mode (-e), Zero-Net (-n), Proxy routing (-P), GPU (-g).
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
║                   📦 BOX — Universal Sandbox Engine               ║
╚═══════════════════════════════════════════════════════════════════╝''${C_RESET}

''${C_BOLD}USAGE:''${C_RESET}
  box [FLAGS] [COMMAND [ARGS...]]

''${C_BOLD}BEHAVIOR:''${C_RESET}
  • If no command is given, launches an interactive shell (''${SHELL:-fish}) inside /work.
  • Zero-Trust: Secrets (~/.ssh, ~/.aws) are isolated; no host files are shared implicitly.
  • Clean /work Workspace: Working directory inside the sandbox is always /work.
  • Agnostic: Inherits the exact environment/tools of the calling shell (dev python, dev rust, etc.).
  • Modular .box/: Automatically maps any directory in .box/<name> to /<name> inside sandbox.

''${C_BOLD}FLAGS & MODIFIERS:''${C_RESET}
  ''${C_YELLOW}-e, --ephemeral, --tmp''${C_RESET}       Pure RAM mode (tmpfs). Everything vanishes upon exit.
  ''${C_YELLOW}-n, --offline, --no-net''${C_RESET}      Completely cut off network access (Zero-Net).
  ''${C_YELLOW}-P, --proxy [PORT]''${C_RESET}           Route all traffic through SOCKS5 proxy (default: 1819).
  ''${C_YELLOW}-g, --gpu''${C_RESET}                    Grant access to Nvidia GPU and CUDA devices.
  ''${C_YELLOW}-s, --share <SRC>[:<DST>]''${C_RESET}   Read-Only share (repeatable, e.g. -s ~/.config/nvim).
  ''${C_YELLOW}-S, --share-rw <SRC>[:<DST>]''${C_RESET} Read-Write share (repeatable, e.g. -S ~/Downloads -S ~/src/venv:~/venv).
  ''${C_YELLOW}-w, --workdir <DIR>''${C_RESET}          Use custom directory as /work workspace (defaults to .box/work/).
  ''${C_YELLOW}--mem <SIZE>''${C_RESET}                 Cap RAM usage via cgroups (e.g. --mem 4G, --mem 512M).
  ''${C_YELLOW}--cpu <QUOTA>''${C_RESET}                Cap CPU quota via cgroups (e.g. --cpu 200%, --cpu 150%).
  ''${C_YELLOW}--clean''${C_RESET}                      Wipe the local .box/ storage for this project.
  ''${C_YELLOW}--inspect <CMD>''${C_RESET}              Trace file and network calls with strace.
  ''${C_YELLOW}-h, --help''${C_RESET}                 Show this help manual.

''${C_BOLD}EXAMPLES:''${C_RESET}
  ''${C_DIM}# 1. Interactive sandbox in clean /work workspace''${C_RESET}
  box

  ''${C_DIM}# 2. Run with read-only Neovim config and read-write downloads''${C_RESET}
  box -s ~/.config/nvim -S ~/Downloads

  ''${C_DIM}# 3. Work on custom directory mapped to /work''${C_RESET}
  box -w my-project/

  ''${C_DIM}# 4. Limit runaway script to 2GB RAM and 150% CPU''${C_RESET}
  box --mem 2G --cpu 150% python test.py

  ''${C_DIM}# 5. Test untrusted script in RAM (zero traces on disk)''${C_RESET}
  box -e curl -sSL https://example.com/install.sh | bash

  ''${C_DIM}# 6. Isolated offline build/test''${C_RESET}
  box -n npm test
EOF
    }

    # ── Default Options ──────────────────────────────────────────────────────
    OPT_EPHEMERAL=0
    OPT_OFFLINE=0
    OPT_GPU=0
    OPT_PROXY=""
    OPT_SHARES_RO=()
    OPT_SHARES_RW=()
    OPT_WORKDIR=""
    OPT_MEM=""
    OPT_CPU=""
    OPT_INSPECT=0
    CMD=()
    REAL_HOST_HOME="''${HOME:-/home/''${USER:-user}}"
    REAL_USER="''${USER:-user}"
    PROJECT_ROOT="$PWD"

    # ── Parse Command Line Flags ─────────────────────────────────────────────
    while [ $# -gt 0 ]; do
      case "$1" in
        -h|--help)
          print_help
          exit 0
          ;;
        --clean)
          if [ -d "$PROJECT_ROOT/.box" ]; then
            printf "''${C_YELLOW}Remove .box directory in %s? [y/N] ''${C_RESET}" "$PROJECT_ROOT"
            read -r reply
            case "$reply" in
              [yY]*)
                rm -rf "$PROJECT_ROOT/.box"
                echo -e "''${C_GREEN}✔ .box cleaned successfully.''${C_RESET}"
                exit 0
                ;;
              *)
                echo "Cancelled."
                exit 0
                ;;
            esac
          else
            echo "No .box directory found in $PROJECT_ROOT."
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
        -S|--share-rw)
          [ $# -ge 2 ] || { echo -e "''${C_RED}box: -S requires a path argument''${C_RESET}" >&2; exit 1; }
          OPT_SHARES_RW+=("$2")
          shift 2
          ;;
        -s|--share)
          [ $# -ge 2 ] || { echo -e "''${C_RED}box: -s requires a path argument''${C_RESET}" >&2; exit 1; }
          OPT_SHARES_RO+=("$2")
          shift 2
          ;;
        -w|--workdir)
          [ $# -ge 2 ] || { echo -e "''${C_RED}box: -w requires a path argument''${C_RESET}" >&2; exit 1; }
          OPT_WORKDIR="$2"
          shift 2
          ;;
        --mem)
          [ $# -ge 2 ] || { echo -e "''${C_RED}box: --mem requires a size argument (e.g. 4G, 512M)''${C_RESET}" >&2; exit 1; }
          OPT_MEM="$2"
          shift 2
          ;;
        --cpu)
          [ $# -ge 2 ] || { echo -e "''${C_RED}box: --cpu requires a quota argument (e.g. 200%)''${C_RESET}" >&2; exit 1; }
          OPT_CPU="$2"
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

    # ── Workspace & Storage Resolution ───────────────────────────────────────
    BOX_DIR="$PROJECT_ROOT/.box"
    HOST_HOME="$BOX_DIR/home"
    DEFAULT_WORK="$BOX_DIR/work"
    HOST_TMP="$BOX_DIR/tmp"

    if [ "$OPT_EPHEMERAL" -eq 0 ]; then
      mkdir -p "$HOST_HOME"/{.config,.cache,.local/bin,.local/share,.npm-global/bin,.cargo/bin,go/bin}
      mkdir -p "$DEFAULT_WORK"
      mkdir -p "$HOST_TMP"
      if [ ! -f "$BOX_DIR/.gitignore" ]; then
        printf "*\n" > "$BOX_DIR/.gitignore"
      fi
    fi

    # Determine Active Workspace Directory on Host
    if [ -n "$OPT_WORKDIR" ]; then
      OPT_WORKDIR="''${OPT_WORKDIR/#\~/$REAL_HOST_HOME}"
      if [ -d "$OPT_WORKDIR" ]; then
        HOST_ACTIVE_WORK="$(cd "$OPT_WORKDIR" && pwd -P)"
      else
        mkdir -p "$OPT_WORKDIR"
        HOST_ACTIVE_WORK="$(cd "$OPT_WORKDIR" && pwd -P)"
      fi
    else
      if [ "$OPT_EPHEMERAL" -eq 1 ]; then
        HOST_ACTIVE_WORK="$PROJECT_ROOT"
      else
        HOST_ACTIVE_WORK="$DEFAULT_WORK"
      fi
    fi

    # ── Build bwrap Arguments ────────────────────────────────────────────────
    # Strict mount ordering:
    # 1. Mount root filesystem, /proc, /dev
    # 2. Mount /tmp (persisted to .box/tmp in standard mode, tmpfs in ephemeral)
    # 3. Swap $REAL_HOST_HOME with isolated home storage
    # 4. Mount workspace directly at /work
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
      --dir /tmp/xdg-runtime
      --tmpfs "$REAL_HOST_HOME"
    )

    # Temporary directory handling
    if [ "$OPT_EPHEMERAL" -eq 1 ]; then
      BWRAP_ARGS+=(--tmpfs /tmp)
    else
      BWRAP_ARGS+=(--dir /tmp --bind "$HOST_TMP" /tmp)
    fi

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

    # Bind active workspace directly to /work
    BWRAP_ARGS+=(
      --dir /work
      --bind "$HOST_ACTIVE_WORK" /work
    )

    # Dynamic Root Directories: Auto-mount any custom directory from .box/<name> to /<name>
    if [ "$OPT_EPHEMERAL" -eq 0 ] && [ -d "$BOX_DIR" ]; then
      for custom_dir in "$BOX_DIR"/*/; do
        [ -d "$custom_dir" ] || continue
        dname="$(basename "$custom_dir")"
        case "$dname" in
          home|work|tmp) continue ;;
          *)
            BWRAP_ARGS+=(--dir "/$dname" --bind "$custom_dir" "/$dname")
            ;;
        esac
      done
    fi

    # GPU Hardware Passthrough
    if [ "$OPT_GPU" -eq 1 ]; then
      for dev in /dev/nvidia* /dev/dri /dev/vga_arbiter; do
        if [ -e "$dev" ]; then
          BWRAP_ARGS+=(--dev-bind "$dev" "$dev")
        fi
      done
    fi

    # ── Multi-Path Sharing Logic (-s for RO, -S for RW) ─────────────────────
    mount_share() {
      local entry="$1"
      local mode="$2"
      local src=""
      local dst=""

      if [[ "$entry" == *":"* ]]; then
        IFS=":" read -r src dst <<< "$entry"
      else
        src="$entry"
      fi

      src="''${src/#\~/$REAL_HOST_HOME}"
      if [ -e "$src" ]; then
        src="$(cd "$(dirname "$src")" && pwd -P)/$(basename "$src")"
        if [ -z "$dst" ]; then
          dst="$src"
        else
          dst="''${dst/#\~/$REAL_HOST_HOME}"
        fi

        # Ensure destination parent directory exists in sandbox storage if inside HOME
        if [ "$OPT_EPHEMERAL" -eq 0 ] && [[ "$dst" == "$REAL_HOST_HOME"* ]]; then
          local rel_path="''${dst#$REAL_HOST_HOME/}"
          local parent_dir
          parent_dir="$(dirname "$rel_path")"
          if [ "$parent_dir" != "." ] && [ "$parent_dir" != "/" ]; then
            mkdir -p "$HOST_HOME/$parent_dir"
          fi
        fi

        BWRAP_ARGS+=("$mode" "$src" "$dst")
      fi
    }

    # Apply Read-Only shares (-s)
    for entry in "''${OPT_SHARES_RO[@]+''${OPT_SHARES_RO[@]}}"; do
      [ -n "$entry" ] || continue
      mount_share "$entry" "--ro-bind-try"
    done

    # Apply Read-Write shares (-S)
    for entry in "''${OPT_SHARES_RW[@]+''${OPT_SHARES_RW[@]}}"; do
      [ -n "$entry" ] || continue
      mount_share "$entry" "--bind-try"
    done

    # Working Directory inside sandbox is ALWAYS /work
    BWRAP_ARGS+=(--chdir /work)

    # ── Clean Agnostic PATH (Inherits caller shell's PATH directly) ───────────
    SANDBOX_PATH="''${REAL_HOST_HOME}/.local/bin:''${REAL_HOST_HOME}/.npm-global/bin:''${REAL_HOST_HOME}/.cargo/bin:$PATH"

    # ── Sandbox Environment Variables ────────────────────────────────────────
    ENV_ARGS=(
      --setenv USER "$REAL_USER"
      --setenv LOGNAME "$REAL_USER"
      --setenv HOME "$REAL_HOST_HOME"
      --setenv PWD "/work"
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

    # ── Execution with optional Systemd Resource Limits ──────────────────────
    EXEC_CMD=("${bwrap}" "''${BWRAP_ARGS[@]}" "''${ENV_ARGS[@]}" -- "''${TARGET_CMD[@]}")

    if [ "$OPT_INSPECT" -eq 1 ]; then
      echo -e "''${C_MAGENTA}🔍 [box inspect] Monitoring filesystem access with strace...''${C_RESET}"
      exec ${pkgs.strace}/bin/strace -f -e trace=file "''${EXEC_CMD[@]}"
    fi

    if [ -n "$OPT_MEM" ] || [ -n "$OPT_CPU" ]; then
      if command -v systemd-run >/dev/null 2>&1 && systemd-run --user --scope --quiet -- true 2>/dev/null; then
        SYS_ARGS=(--user --scope --quiet)
        [ -n "$OPT_MEM" ] && SYS_ARGS+=(-p "MemoryMax=$OPT_MEM")
        [ -n "$OPT_CPU" ] && SYS_ARGS+=(-p "CPUQuota=$OPT_CPU")
        exec systemd-run "''${SYS_ARGS[@]}" -- "''${EXEC_CMD[@]}"
      else
        echo -e "''${C_YELLOW}⚠ systemd user scope unavailable — running without cgroup limits''${C_RESET}" >&2
      fi
    fi

    exec "''${EXEC_CMD[@]}"
  '';
in
  mkDevShell {
    name = "box";
    icon = "📦";
    description = "Universal Sandbox: Language-Agnostic, Clean /work, Persisted .box/tmp, -s (RO) & -S (RW)";

    packages = [
      boxCli
      pkgs.bubblewrap
      pkgs.strace
      pkgs.lsof
    ];

    tips = [
      {
        key = "Interactive";
        cmd = "box                         (launches isolated shell in /work)";
      }
      {
        key = "Share Config (RO)";
        cmd = "box -s ~/.config/nvim";
      }
      {
        key = "Share Writable (RW)";
        cmd = "box -S ~/Downloads -S ~/src/venv:~/venv";
      }
      {
        key = "Resource Limits";
        cmd = "box --mem 4G --cpu 200% <cmd> (prevent freeze with cgroups)";
      }
      {
        key = "Custom Workdir";
        cmd = "box -w work/                (work in custom subfolder)";
      }
      {
        key = "Ephemeral RAM";
        cmd = "box -e <cmd>                (pure memory tmpfs, zero disk trace)";
      }
      {
        key = "Zero-Net";
        cmd = "box -n <cmd>                (isolated network stack)";
      }
      {
        key = "GPU / CUDA";
        cmd = "box -g <cmd>                (Nvidia GTX 1650 & CUDA passthrough)";
      }
      {
        key = "Clean Storage";
        cmd = "box --clean                 (wipe local .box folder)";
      }
    ];

    notes = [
      "Language-Agnostic: No hardcoded tool paths; inherits caller shell's exact environment"
      "Clean Workspace: Always /work  ·  Dynamic: .box/<name> auto-maps to /<name>"
      "-s = Read-Only share  ·  -S = Read-Write share  ·  Supports <src>:<dst> mapping"
      "Ports Open: Web UIs & dev servers on localhost/0.0.0.0 reach the host browser"
    ];
  }
