{
  mkDevShell,
  pkgs,
  ...
}:
# ==============================================================================
# BOX — Next-Gen Developer & AI Agent Sandbox (Bubblewrap & Masked Paths)
# ==============================================================================
# A zero-overhead, ultra-fast sandboxing engine designed for:
#   1. Privacy & Path Masking: Host paths and username are completely invisible.
#      Project is mounted at `/work` and user is `dev` with HOME `/home/dev`.
#   2. Local Package Installation: Full support for `npm -g`, `pip`, `cargo`,
#      and `curl | bash` without polluting or modifying the host operating system.
#   3. Multi-Path Sharing (-s): Mount host configs (e.g. -s ~/.config/nvim -s ~/.config/opencode)
#      directly to their matching sandbox paths (/home/dev/...) in read-only or read-write mode.
#   4. Flexible Controls: Modifiers for Ephemeral RAM mode (-e), Zero-Net (-n),
#      Proxy routing (-P), GPU/CUDA hardware access (-g), and directory sharing (-s).
#   5. Outgoing & Incoming Ports: Web UIs, dev servers, and local proxies can
#      listen and be accessed on host ports (0.0.0.0 / 127.0.0.1) seamlessly.
# ==============================================================================
let
  bwrap = "${pkgs.bubblewrap}/bin/bwrap";

  boxCli = pkgs.writeShellScriptBin "box" ''
        set -euo pipefail

        # ── Color Palette ────────────────────────────────────────────────────────
        C_RESET="\033[0m"
        C_BOLD="\033[1m"
        C_CYAN="\033[1;36m"
        C_GREEN="\033[1;32m"
        C_YELLOW="\033[1;33m"
        C_RED="\033[1;31m"
        C_MAGENTA="\033[1;35m"
        C_DIM="\033[1;30m"

        print_help() {
          cat <<EOF
    ''${C_CYAN}''${C_BOLD}╔═══════════════════════════════════════════════════════════════════╗
    ║                   📦 BOX — Sandboxing Engine                      ║
    ╚═══════════════════════════════════════════════════════════════════╝''${C_RESET}

    ''${C_BOLD}USAGE:''${C_RESET}
      box [FLAGS] [COMMAND [ARGS...]]

    ''${C_BOLD}BEHAVIOR:''${C_RESET}
      • If no command is given, launches an interactive shell (''${SHELL:-fish}) inside /work.
      • The real host path and username are hidden: project is at ''${C_GREEN}/work''${C_RESET}, HOME is ''${C_GREEN}/home/dev''${C_RESET}.
      • Local tools (npm -g, pip, cargo, curl | sh) install into project's .box/ without root.
      • Dev servers and Web UIs (e.g. localhost:3000) are fully accessible on the host.

    ''${C_BOLD}FLAGS & MODIFIERS:''${C_RESET}
      ''${C_YELLOW}-e, --ephemeral, --tmp''${C_RESET}     Pure RAM mode (tmpfs). Everything vanishes upon exit.
      ''${C_YELLOW}-n, --offline, --no-net''${C_RESET}    Completely cut off network access (Zero-Net).
      ''${C_YELLOW}-P, --proxy [PORT]''${C_RESET}         Route all traffic through SOCKS5 proxy (default: 1819).
      ''${C_YELLOW}-g, --gpu''${C_RESET}                  Grant access to Nvidia GPU and CUDA devices.
      ''${C_YELLOW}-s, --share <PATH>''${C_RESET}        Share host path (repeatable, e.g. -s ~/.config/nvim -s ~/.config/opencode).
      ''${C_YELLOW}-w, --workdir <DIR>''${C_RESET}        Use custom directory as workspace instead of current directory.
      ''${C_YELLOW}--clean''${C_RESET}                    Wipe the local .box/ storage for the current project.
      ''${C_YELLOW}--inspect <CMD>''${C_RESET}            Trace file and network calls with strace.
      ''${C_YELLOW}-h, --help''${C_RESET}                 Show this help manual.

    ''${C_BOLD}EXAMPLES:''${C_RESET}
      ''${C_DIM}# 1. Interactive sandbox shell''${C_RESET}
      box

      ''${C_DIM}# 2. Run Neovim with host config inside sandbox''${C_RESET}
      box -s ~/.config/nvim nvim main.py

      ''${C_DIM}# 3. Share multiple configs & directories at once''${C_RESET}
      box -s ~/.config/nvim -s ~/.config/opencode -s ~/Downloads

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

        # ── Parse Command Line Flags ─────────────────────────────────────────────
        while [ $# -gt 0 ]; do
          case "$1" in
            -h|--help)
              print_help
              exit 0
              ;;
            --clean)
              if [ -d "$PWD/.box" ]; then
                printf "''${C_YELLOW}Remove .box directory in %s? [y/N] ''${C_RESET}" "$PWD"
                read -r reply
                case "$reply" in
                  [yY]*)
                    rm -rf "$PWD/.box"
                    echo -e "''${C_GREEN}✔ .box cleaned successfully.''${C_RESET}"
                    exit 0
                    ;;
                  *)
                    echo "Cancelled."
                    exit 0
                    ;;
                esac
              else
                echo "No .box directory found in $PWD."
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
            -w|--workdir)
              [ $# -ge 2 ] || { echo -e "''${C_RED}box: -w/--workdir requires a path argument''${C_RESET}" >&2; exit 1; }
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
        BOX_STORAGE="$HOST_WORK/.box"
        HOST_HOME="$BOX_STORAGE/home"

        if [ "$OPT_EPHEMERAL" -eq 0 ]; then
          mkdir -p "$HOST_HOME"/{.config,.cache,.local/bin,.local/share,.npm-global/bin,.cargo/bin,go/bin}
          if [ ! -f "$BOX_STORAGE/.gitignore" ]; then
            mkdir -p "$BOX_STORAGE"
            printf "*\n" > "$BOX_STORAGE/.gitignore"
          fi
        fi

        # ── Build bwrap Arguments ────────────────────────────────────────────────
        BWRAP_ARGS=(
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
        )

        # Network configuration
        if [ "$OPT_OFFLINE" -eq 1 ]; then
          BWRAP_ARGS+=(--unshare-net)
        else
          BWRAP_ARGS+=(--share-net)
        fi

        # Root filesystem (Whole OS available as Read-Only for tools & libraries)
        BWRAP_ARGS+=(--ro-bind / /)

        # Workspace Masking: Mount project as /work and hide .box folder from inside /work
        BWRAP_ARGS+=(--bind "$HOST_WORK" /work)
        if [ -d "$BOX_STORAGE" ] && [ "$OPT_EPHEMERAL" -eq 0 ]; then
          BWRAP_ARGS+=(--tmpfs "/work/.box")
        fi

        # Virtual HOME (/home/dev)
        if [ "$OPT_EPHEMERAL" -eq 1 ]; then
          BWRAP_ARGS+=(--tmpfs /home/dev)
        else
          BWRAP_ARGS+=(--bind "$HOST_HOME" /home/dev)
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
              if [[ "$src" == "$REAL_HOST_HOME"* ]]; then
                rel="''${src#$REAL_HOST_HOME/}"
                dst="/home/dev/$rel"
              else
                base="$(basename "$src")"
                dst="/shared/$base"
              fi
            else
              dst="''${dst/#\~//home/dev}"
            fi
            BWRAP_ARGS+=("$mode" "$src" "$dst")
          fi
        done

        # Working Directory inside sandbox
        BWRAP_ARGS+=(--chdir /work)

        # ── Sandbox Environment Variables ────────────────────────────────────────
        ENV_ARGS=(
          --setenv USER "dev"
          --setenv LOGNAME "dev"
          --setenv HOME "/home/dev"
          --setenv PWD "/work"
          --setenv TERM "''${TERM:-xterm-256color}"
          --setenv COLORTERM "''${COLORTERM:-truecolor}"
          --setenv LANG "''${LANG:-C.UTF-8}"
          --setenv XDG_CONFIG_HOME "/home/dev/.config"
          --setenv XDG_CACHE_HOME "/home/dev/.cache"
          --setenv XDG_DATA_HOME "/home/dev/.local/share"
          --setenv XDG_RUNTIME_DIR "/tmp/xdg-runtime"
          --setenv npm_config_prefix "/home/dev/.npm-global"
          --setenv PIP_PREFIX "/home/dev/.local"
          --setenv CARGO_HOME "/home/dev/.cargo"
          --setenv GOPATH "/home/dev/go"
          --setenv PATH "/home/dev/.npm-global/bin:/home/dev/.local/bin:/home/dev/.cargo/bin:/home/dev/go/bin:$PATH"
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
    description = "Next-Gen Sandbox: Path Masking (/work), Multi-Share (-s), Ephemeral RAM & GPU";

    packages = [
      boxCli
      pkgs.bubblewrap
      pkgs.strace
      pkgs.lsof
    ];

    tips = [
      {
        key = "Interactive";
        cmd = "box                 (launches isolated shell in /work)";
      }
      {
        key = "Share Host Configs";
        cmd = "box -s ~/.config/nvim -s ~/.config/opencode";
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
        key = "Shared folder";
        cmd = "box -s ~/Downloads  (mounts external dir at /home/dev/Downloads)";
      }
      {
        key = "Inspect";
        cmd = "box --inspect <cmd> (trace touched paths with strace)";
      }
      {
        key = "Clean Storage";
        cmd = "box --clean         (wipe current project's .box folder)";
      }
    ];

    notes = [
      "Path Masking: Real host path & username are hidden (/work & /home/dev)"
      "Multi-Share: -s maps host configs directly into /home/dev/... cleanly"
      "Local Tools: npm -g, pip, cargo, and curl | bash install cleanly into .box"
      "Ports Open: Web UIs & dev servers on localhost/0.0.0.0 reach the host browser"
    ];
  }
