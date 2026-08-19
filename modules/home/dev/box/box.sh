# shellcheck shell=bash
set -euo pipefail

_BAKED_PROXY_PORT="@proxyPort@"
if [[ "${PROXY_PORT:-}" =~ ^[0-9]+$ ]] && [ "$PROXY_PORT" -ge 1 ] && [ "$PROXY_PORT" -le 65535 ]; then
  DEFAULT_PROXY_PORT="$PROXY_PORT"
else
  DEFAULT_PROXY_PORT="$_BAKED_PROXY_PORT"
fi

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
${C_CYAN}${C_BOLD}╔═══════════════════════════════════════════════════════════════════╗
║                   📦 BOX — Universal Sandbox Engine               ║
╚═══════════════════════════════════════════════════════════════════╝${C_RESET}

${C_BOLD}USAGE:${C_RESET}
  box [FLAGS] [COMMAND [ARGS...]]

${C_BOLD}BEHAVIOR:${C_RESET}
  • If no command is given, launches an interactive shell (${SHELL:-fish}) inside /work.
  • Home isolation: Files such as ~/.ssh and ~/.aws are hidden; use --secure to clear host variables too.
  • Clean /work Workspace: Working directory inside the sandbox is always /work.
  • Agnostic: Inherits caller tools/PATH; --secure keeps tools while clearing unrelated variables.
  • Modular .box/: Automatically maps any directory in .box/<name> to /<name> inside sandbox.

${C_BOLD}FLAGS & MODIFIERS:${C_RESET}
  ${C_YELLOW}-e, --ephemeral, --tmp${C_RESET}       Pure RAM mode (tmpfs). Everything vanishes upon exit.
  ${C_YELLOW}--secure${C_RESET}                     Clear inherited environment and hide broad /run and /var mounts.
  ${C_YELLOW}--dry-run${C_RESET}                    Print the sandbox plan without creating or running anything.
  ${C_YELLOW}-n, --offline, --no-net${C_RESET}      Completely cut off network access (Zero-Net).
  ${C_YELLOW}--net <MODE>${C_RESET}                 Network mode: host, none, or proxy[:PORT].
  ${C_YELLOW}-P, --proxy [PORT]${C_RESET}           Set SOCKS5 proxy environment (default: ${DEFAULT_PROXY_PORT}).
  ${C_YELLOW}-g, --gpu${C_RESET}                    Grant access to Nvidia GPU and CUDA devices.
  ${C_YELLOW}-s, --share <SRC>[:<DST>]${C_RESET}   Read-Only share (repeatable).
  ${C_YELLOW}-S, --share-rw <SRC>[:<DST>]${C_RESET} Read-Write share (repeatable).
  ${C_YELLOW}-w, --workdir <DIR>${C_RESET}          Use custom directory as /work (default: .box/work/).
  ${C_YELLOW}--clear-env${C_RESET}                  Start with a clean environment while preserving Box defaults.
  ${C_YELLOW}--env <KEY=VALUE>${C_RESET}            Set one environment variable (repeatable).
  ${C_YELLOW}--env-pass <KEY>${C_RESET}             Pass one host variable explicitly (repeatable).
  ${C_YELLOW}--profile <NAME>${C_RESET}             Load trusted options from ~/.config/box/profiles/NAME.conf.
  ${C_YELLOW}--profiles${C_RESET}                   List available trusted profiles.
  ${C_YELLOW}--path / --status${C_RESET}            Print local Box path or storage status and exit.
  ${C_YELLOW}--mem <SIZE>${C_RESET}                 Cap RAM usage via cgroups (e.g. --mem 4G).
  ${C_YELLOW}--cpu <QUOTA>${C_RESET}                Cap CPU quota (e.g. --cpu 200%).
  ${C_YELLOW}--clean${C_RESET}                      Wipe the local .box/ storage for this project.
  ${C_YELLOW}--inspect${C_RESET}                    Trace user/workspace file access for the target command.
  ${C_YELLOW}--inspect-all${C_RESET}                Trace all target-command file access (verbose).
  ${C_YELLOW}-h, --help${C_RESET}                   Show this help manual.

${C_BOLD}EXAMPLES:${C_RESET}
  ${C_DIM}# 1. Interactive sandbox in clean /work workspace${C_RESET}
  box

  ${C_DIM}# 2. Run with read-only Neovim config and read-write downloads${C_RESET}
  box -s ~/.config/nvim -S ~/Downloads

  ${C_DIM}# 3. Work on custom directory mapped to /work${C_RESET}
  box -w my-project/

  ${C_DIM}# 4. Limit runaway script to 2GB RAM and 150% CPU${C_RESET}
  box --mem 2G --cpu 150% python test.py

  ${C_DIM}# 5. Preview a strict sandbox without starting it${C_RESET}
  box --secure --dry-run python suspicious.py

  ${C_DIM}# 6. Run an entire installer pipeline inside ephemeral Box${C_RESET}
  box -e bash -lc 'curl -sSL https://example.com/install.sh | bash'

  ${C_DIM}# 7. Isolated offline build/test${C_RESET}
  box --net none npm test
EOF
}

# ── Default Options ──────────────────────────────────────────────────────
OPT_EPHEMERAL=0
OPT_SECURE=0
OPT_DRY_RUN=0
OPT_CLEAR_ENV=0
OPT_OFFLINE=0
OPT_GPU=0
OPT_PROXY=""
OPT_SHARES_RO=()
OPT_SHARES_RW=()
OPT_ENV_SET=()
OPT_ENV_PASS=()
OPT_WORKDIR=""
OPT_MEM=""
OPT_CPU=""
OPT_INSPECT=0
CMD=()
REAL_HOST_HOME="${HOME:-/home/${USER:-user}}"
REAL_USER="${USER:-user}"
PROJECT_ROOT="$PWD"
PROFILE_DIR="${XDG_CONFIG_HOME:-$REAL_HOST_HOME/.config}/box/profiles"
LOADED_PROFILE_ARGS=()

list_profiles() {
  if [ ! -d "$PROFILE_DIR" ]; then
    echo "No Box profiles found in $PROFILE_DIR"
    return 0
  fi

  local found=0 file
  for file in "$PROFILE_DIR"/*.conf; do
    [ -f "$file" ] || continue
    basename "$file" .conf
    found=1
  done
  [ "$found" -eq 1 ] || echo "No Box profiles found in $PROFILE_DIR"
}

load_profile() {
  local name="$1"
  local file line

  [[ "$name" =~ ^[A-Za-z0-9._-]+$ ]] || {
    echo -e "${C_RED}box: invalid profile name: $name${C_RESET}" >&2
    exit 1
  }
  file="$PROFILE_DIR/$name.conf"
  [ -f "$file" ] || {
    echo -e "${C_RED}box: profile not found: $file${C_RESET}" >&2
    exit 1
  }

  LOADED_PROFILE_ARGS=()
  while IFS= read -r line || [ -n "$line" ]; do
    line="$(printf '%s' "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [ -n "$line" ] || continue
    [[ "$line" == \#* ]] && continue
    [[ "$line" != "--profile" && "$line" != "--profiles" ]] || {
      echo -e "${C_RED}box: nested profiles are not allowed in $file${C_RESET}" >&2
      exit 1
    }
    LOADED_PROFILE_ARGS+=("$line")
  done < "$file"
}

print_storage_status() {
  local box_dir="$PROJECT_ROOT/.box"
  printf '%sBox storage%s\n' "$C_CYAN" "$C_RESET"
  printf '  root  %s\n' "$box_dir"
  if [ ! -d "$box_dir" ]; then
    printf '  state empty (not created)\n'
    return 0
  fi

  local name path size
  for name in home work tmp; do
    path="$box_dir/$name"
    if [ -e "$path" ]; then
      size="$(du -sh "$path" 2>/dev/null | cut -f1)"
      printf '  %-5s %-8s %s\n' "$name" "${size:-?}" "$path"
    else
      printf '  %-5s %-8s %s\n' "$name" "empty" "$path"
    fi
  done
  printf '  total %-8s\n' "$(du -sh "$box_dir" 2>/dev/null | cut -f1)"
}

# ── Parse Command Line Flags ─────────────────────────────────────────────
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      print_help
      exit 0
      ;;
    --path)
      printf '%s\n' "$PROJECT_ROOT/.box"
      exit 0
      ;;
    --status)
      print_storage_status
      exit 0
      ;;
    --profiles)
      list_profiles
      exit 0
      ;;
    --profile)
      [ $# -ge 2 ] || { echo -e "${C_RED}box: --profile requires a name${C_RESET}" >&2; exit 1; }
      load_profile "$2"
      shift 2
      set -- "${LOADED_PROFILE_ARGS[@]}" "$@"
      ;;
    --secure)
      OPT_SECURE=1
      OPT_CLEAR_ENV=1
      shift
      ;;
    --dry-run)
      OPT_DRY_RUN=1
      shift
      ;;
    --clear-env)
      OPT_CLEAR_ENV=1
      shift
      ;;
    --env)
      [ $# -ge 2 ] || { echo -e "${C_RED}box: --env requires KEY=VALUE${C_RESET}" >&2; exit 1; }
      [[ "$2" == *=* ]] || { echo -e "${C_RED}box: --env requires KEY=VALUE${C_RESET}" >&2; exit 1; }
      OPT_ENV_SET+=("$2")
      shift 2
      ;;
    --env-pass)
      [ $# -ge 2 ] || { echo -e "${C_RED}box: --env-pass requires a variable name${C_RESET}" >&2; exit 1; }
      OPT_ENV_PASS+=("$2")
      shift 2
      ;;
    --clean)
      if [ -d "$PROJECT_ROOT/.box" ]; then
        printf "${C_YELLOW}Remove .box directory in %s? [y/N] ${C_RESET}" "$PROJECT_ROOT"
        read -r reply
        case "$reply" in
          [yY]*)
            rm -rf "$PROJECT_ROOT/.box"
            echo -e "${C_GREEN}✔ .box cleaned successfully.${C_RESET}"
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
      OPT_PROXY=""
      shift
      ;;
    --net)
      [ $# -ge 2 ] || { echo -e "${C_RED}box: --net requires host, none, or proxy[:PORT]${C_RESET}" >&2; exit 1; }
      case "$2" in
        host)
          OPT_OFFLINE=0
          OPT_PROXY=""
          ;;
        none)
          OPT_OFFLINE=1
          OPT_PROXY=""
          ;;
        proxy)
          OPT_OFFLINE=0
          OPT_PROXY="$DEFAULT_PROXY_PORT"
          ;;
        proxy:*)
          OPT_OFFLINE=0
          OPT_PROXY="${2#proxy:}"
          [[ "$OPT_PROXY" =~ ^[0-9]+$ ]] || {
            echo -e "${C_RED}box: invalid proxy port in --net $2${C_RESET}" >&2
            exit 1
          }
          ;;
        *)
          echo -e "${C_RED}box: invalid network mode: $2${C_RESET}" >&2
          exit 1
          ;;
      esac
      shift 2
      ;;
    -g|--gpu)
      OPT_GPU=1
      shift
      ;;
    -P|--proxy)
      OPT_OFFLINE=0
      if [ $# -ge 2 ] && [[ "$2" =~ ^[0-9]+$ ]]; then
        OPT_PROXY="$2"
        shift 2
      else
        OPT_PROXY="$DEFAULT_PROXY_PORT"
        shift
      fi
      ;;
    -S|--share-rw)
      [ $# -ge 2 ] || { echo -e "${C_RED}box: -S requires a path argument${C_RESET}" >&2; exit 1; }
      OPT_SHARES_RW+=("$2")
      shift 2
      ;;
    -s|--share)
      [ $# -ge 2 ] || { echo -e "${C_RED}box: -s requires a path argument${C_RESET}" >&2; exit 1; }
      OPT_SHARES_RO+=("$2")
      shift 2
      ;;
    -w|--workdir)
      [ $# -ge 2 ] || { echo -e "${C_RED}box: -w requires a path argument${C_RESET}" >&2; exit 1; }
      OPT_WORKDIR="$2"
      shift 2
      ;;
    --mem)
      [ $# -ge 2 ] || { echo -e "${C_RED}box: --mem requires a size argument (e.g. 4G, 512M)${C_RESET}" >&2; exit 1; }
      OPT_MEM="$2"
      shift 2
      ;;
    --cpu)
      [ $# -ge 2 ] || { echo -e "${C_RED}box: --cpu requires a quota argument (e.g. 200%)${C_RESET}" >&2; exit 1; }
      OPT_CPU="$2"
      shift 2
      ;;
    --inspect)
      OPT_INSPECT=1
      shift
      ;;
    --inspect-all)
      OPT_INSPECT=2
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

# Determine the isolated workspace. The caller's current directory is never
# mounted implicitly: persistent mode uses .box/work, ephemeral mode uses a
# tmpfs, and -w is the only way to select another host directory.
WORK_MODE="bind"
if [ -n "$OPT_WORKDIR" ]; then
  OPT_WORKDIR="${OPT_WORKDIR/#\~/$REAL_HOST_HOME}"
  HOST_ACTIVE_WORK="$(realpath -m -- "$OPT_WORKDIR")"
elif [ "$OPT_EPHEMERAL" -eq 1 ]; then
  WORK_MODE="tmpfs"
  HOST_ACTIVE_WORK=""
else
  HOST_ACTIVE_WORK="$DEFAULT_WORK"
fi

validate_share() {
  local entry="$1" src
  if [[ "$entry" == *":"* ]]; then
    src="${entry%%:*}"
  else
    src="$entry"
  fi
  src="${src/#\~/$REAL_HOST_HOME}"
  [ -e "$src" ] || {
    echo -e "${C_RED}box: share source does not exist: $src${C_RESET}" >&2
    exit 1
  }
}

for entry in "${OPT_SHARES_RO[@]+${OPT_SHARES_RO[@]}}"; do
  [ -n "$entry" ] && validate_share "$entry"
done
for entry in "${OPT_SHARES_RW[@]+${OPT_SHARES_RW[@]}}"; do
  [ -n "$entry" ] && validate_share "$entry"
done

print_plan() {
  local network env_mode home_mode tmp_mode work_value
  if [ "$OPT_OFFLINE" -eq 1 ]; then
    network="none"
  elif [ -n "$OPT_PROXY" ]; then
    network="proxy:$OPT_PROXY (environment)"
  else
    network="host"
  fi

  [ "$OPT_CLEAR_ENV" -eq 1 ] && env_mode="clean + Box defaults" || env_mode="inherited + Box defaults"
  [ "$OPT_EPHEMERAL" -eq 1 ] && home_mode="tmpfs" || home_mode="$HOST_HOME"
  [ "$OPT_EPHEMERAL" -eq 1 ] && tmp_mode="tmpfs" || tmp_mode="$HOST_TMP"
  [ "$WORK_MODE" = "tmpfs" ] && work_value="tmpfs" || work_value="$HOST_ACTIVE_WORK"

  printf '%s╭─ 📦 Box execution plan%s\n' "$C_CYAN" "$C_RESET"
  printf '%s│%s  %-11s %s\n' "$C_CYAN" "$C_RESET" "Mode" "$([ "$OPT_SECURE" -eq 1 ] && echo secure || echo standard)"
  printf '%s│%s  %-11s %s → /work\n' "$C_CYAN" "$C_RESET" "Work" "$work_value"
  printf '%s│%s  %-11s %s\n' "$C_CYAN" "$C_RESET" "Home" "$home_mode"
  printf '%s│%s  %-11s %s\n' "$C_CYAN" "$C_RESET" "Temp" "$tmp_mode"
  printf '%s│%s  %-11s %s\n' "$C_CYAN" "$C_RESET" "Network" "$network"
  printf '%s│%s  %-11s %s\n' "$C_CYAN" "$C_RESET" "Environment" "$env_mode"
  printf '%s│%s  %-11s %s\n' "$C_CYAN" "$C_RESET" "GPU" "$([ "$OPT_GPU" -eq 1 ] && echo enabled || echo disabled)"
  printf '%s│%s  %-11s %s\n' "$C_CYAN" "$C_RESET" "Memory" "${OPT_MEM:-unlimited}"
  printf '%s│%s  %-11s %s\n' "$C_CYAN" "$C_RESET" "CPU" "${OPT_CPU:-unlimited}"

  local entry
  for entry in "${OPT_SHARES_RO[@]+${OPT_SHARES_RO[@]}}"; do
    [ -n "$entry" ] && printf '%s│%s  %-11s %s\n' "$C_CYAN" "$C_RESET" "Share RO" "$entry"
  done
  for entry in "${OPT_SHARES_RW[@]+${OPT_SHARES_RW[@]}}"; do
    [ -n "$entry" ] && printf '%s│%s  %-11s %s\n' "$C_CYAN" "$C_RESET" "Share RW" "$entry"
  done
  for entry in "${OPT_ENV_PASS[@]+${OPT_ENV_PASS[@]}}"; do
    [ -n "$entry" ] && printf '%s│%s  %-11s %s\n' "$C_CYAN" "$C_RESET" "Env pass" "$entry"
  done
  for entry in "${OPT_ENV_SET[@]+${OPT_ENV_SET[@]}}"; do
    [ -n "$entry" ] && printf '%s│%s  %-11s %s\n' "$C_CYAN" "$C_RESET" "Env set" "${entry%%=*}=…"
  done

  printf '%s│%s  %-11s' "$C_CYAN" "$C_RESET" "Command"
  if [ ${#CMD[@]} -eq 0 ]; then
    printf ' %s\n' "${SHELL:-fish}"
  else
    printf ' %q' "${CMD[@]}"
    printf '\n'
  fi
  printf '%s╰─ no files created; no process started%s\n' "$C_CYAN" "$C_RESET"
}

if [ "$OPT_DRY_RUN" -eq 1 ]; then
  print_plan
  exit 0
fi

if [ "$OPT_EPHEMERAL" -eq 0 ]; then
  mkdir -p "$HOST_HOME"/{.config,.cache,.local/bin,.local/share,.npm-global/bin,.cargo/bin,go/bin}
  mkdir -p "$DEFAULT_WORK" "$HOST_TMP"
  if [ ! -f "$BOX_DIR/.gitignore" ]; then
    printf "*\n" > "$BOX_DIR/.gitignore"
  fi
fi

if [ "$WORK_MODE" = "bind" ] && [ ! -d "$HOST_ACTIVE_WORK" ]; then
  mkdir -p "$HOST_ACTIVE_WORK"
  HOST_ACTIVE_WORK="$(cd "$HOST_ACTIVE_WORK" && pwd -P)"
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
  --tmpfs "$REAL_HOST_HOME"
)
INSPECT_PATHS=(/work "$REAL_HOST_HOME" /tmp)

# Standard mode retains host runtime compatibility. Secure mode deliberately
# omits these broad mounts; networking remains independent and stays enabled
# unless -n / --net none is requested.
if [ "$OPT_SECURE" -eq 0 ]; then
  BWRAP_ARGS+=(
    --ro-bind-try /run /run
    --ro-bind-try /var /var
  )
fi

# Temporary directory handling
if [ "$OPT_EPHEMERAL" -eq 1 ]; then
  BWRAP_ARGS+=(--tmpfs /tmp)
else
  BWRAP_ARGS+=(--dir /tmp --bind "$HOST_TMP" /tmp)
fi
# Create this after the /tmp mount so the mount does not hide it.
BWRAP_ARGS+=(--dir /tmp/xdg-runtime)

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

# Bind the explicit/persistent workspace or create an in-memory /work.
if [ "$WORK_MODE" = "tmpfs" ]; then
  BWRAP_ARGS+=(--tmpfs /work)
else
  BWRAP_ARGS+=(--dir /work --bind "$HOST_ACTIVE_WORK" /work)
fi

# Dynamic Root Directories: Auto-mount any custom directory from .box/<name> to /<name>
if [ "$OPT_EPHEMERAL" -eq 0 ] && [ -d "$BOX_DIR" ]; then
  for custom_dir in "$BOX_DIR"/*/; do
    [ -d "$custom_dir" ] || continue
    dname="$(basename "$custom_dir")"
    case "$dname" in
      home|work|tmp) continue ;;
      *)
        BWRAP_ARGS+=(--dir "/$dname" --bind "$custom_dir" "/$dname")
        INSPECT_PATHS+=("/$dname")
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

  # Secure mode does not expose all of /run, so grant only the NixOS driver
  # libraries required by explicitly requested GPU workloads.
  if [ "$OPT_SECURE" -eq 1 ]; then
    for driver_dir in /run/opengl-driver /run/opengl-driver-32; do
      [ -e "$driver_dir" ] && BWRAP_ARGS+=(--ro-bind "$driver_dir" "$driver_dir")
    done
  fi
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

  src="${src/#\~/$REAL_HOST_HOME}"
  [ -e "$src" ] || {
    echo -e "${C_RED}box: share source does not exist: $src${C_RESET}" >&2
    exit 1
  }
  src="$(cd "$(dirname "$src")" && pwd -P)/$(basename "$src")"
  if [ -z "$dst" ]; then
    dst="$src"
  else
    dst="${dst/#\~/$REAL_HOST_HOME}"
  fi

  # Ensure destination parent directory exists in sandbox storage if inside HOME
  if [ "$OPT_EPHEMERAL" -eq 0 ] && [[ "$dst" == "$REAL_HOST_HOME"* ]]; then
    local rel_path="${dst#$REAL_HOST_HOME/}"
    local parent_dir
    parent_dir="$(dirname "$rel_path")"
    if [ "$parent_dir" != "." ] && [ "$parent_dir" != "/" ]; then
      mkdir -p "$HOST_HOME/$parent_dir"
    fi
  fi

  BWRAP_ARGS+=("$mode" "$src" "$dst")
  INSPECT_PATHS+=("$dst")
}

# Apply Read-Only shares (-s)
for entry in "${OPT_SHARES_RO[@]+${OPT_SHARES_RO[@]}}"; do
  [ -n "$entry" ] || continue
  mount_share "$entry" "--ro-bind"
done

# Apply Read-Write shares (-S)
for entry in "${OPT_SHARES_RW[@]+${OPT_SHARES_RW[@]}}"; do
  [ -n "$entry" ] || continue
  mount_share "$entry" "--bind"
done

# Working Directory inside sandbox is ALWAYS /work
BWRAP_ARGS+=(--chdir /work)

# ── Clean Agnostic PATH (Inherits caller shell's PATH directly) ───────────
SANDBOX_PATH="${REAL_HOST_HOME}/.local/bin:${REAL_HOST_HOME}/.npm-global/bin:${REAL_HOST_HOME}/.cargo/bin:$PATH"

# ── Sandbox Environment Variables ────────────────────────────────────────
ENV_ARGS=()
[ "$OPT_CLEAR_ENV" -eq 1 ] && ENV_ARGS+=(--clearenv)
ENV_ARGS+=(
  --setenv USER "$REAL_USER"
  --setenv LOGNAME "$REAL_USER"
  --setenv HOME "$REAL_HOST_HOME"
  --setenv PWD "/work"
  --setenv TMPDIR "/tmp"
  --setenv TMP "/tmp"
  --setenv TEMP "/tmp"
  --setenv TERM "${TERM:-xterm-256color}"
  --setenv COLORTERM "${COLORTERM:-truecolor}"
  --setenv LANG "${LANG:-C.UTF-8}"
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
[ -n "${NIX_LD:-}" ] && ENV_ARGS+=(--setenv NIX_LD "$NIX_LD")
[ -n "${NIX_LD_LIBRARY_PATH:-}" ] && ENV_ARGS+=(--setenv NIX_LD_LIBRARY_PATH "$NIX_LD_LIBRARY_PATH")

# Explicit environment controls. They are most useful with --secure or
# --clear-env, while normal mode keeps its existing inherited environment.
for name in "${OPT_ENV_PASS[@]+${OPT_ENV_PASS[@]}}"; do
  [[ "$name" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || {
    echo -e "${C_RED}box: invalid environment name: $name${C_RESET}" >&2
    exit 1
  }
  [[ -v "$name" ]] || {
    echo -e "${C_RED}box: host variable is not set: $name${C_RESET}" >&2
    exit 1
  }
  ENV_ARGS+=(--setenv "$name" "${!name}")
done

for assignment in "${OPT_ENV_SET[@]+${OPT_ENV_SET[@]}}"; do
  name="${assignment%%=*}"
  value="${assignment#*=}"
  [[ "$name" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || {
    echo -e "${C_RED}box: invalid environment assignment: $assignment${C_RESET}" >&2
    exit 1
  }
  ENV_ARGS+=(--setenv "$name" "$value")
done

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
    --setenv NO_PROXY "127.0.0.1,localhost,::1"
    --setenv no_proxy "127.0.0.1,localhost,::1"
  )
fi

# ── Determine Target Command ─────────────────────────────────────────────
if [ ${#CMD[@]} -eq 0 ]; then
  if command -v fish >/dev/null 2>&1; then
    TARGET_CMD=(fish)
  else
    TARGET_CMD=(bash)
  fi
else
  TARGET_CMD=("${CMD[@]}")
fi

# ── Execution with optional inspection and Systemd Resource Limits ───────
# Inspect the target from inside Box. This avoids tracing Bubblewrap's own
# namespace/mount setup and keeps resource limits effective.
if [ "$OPT_INSPECT" -gt 0 ]; then
  STRACE_ARGS=(-f -qq -e trace=%file)
  if [ "$OPT_INSPECT" -eq 1 ]; then
    for path in "${INSPECT_PATHS[@]}"; do
      STRACE_ARGS+=(-P "$path")
    done
    echo -e "${C_MAGENTA}🔍 [box inspect] Tracing target access under /work, /tmp, Home and explicit shares...${C_RESET}"
  else
    echo -e "${C_MAGENTA}🔍 [box inspect-all] Tracing all target file access...${C_RESET}"
  fi
  TARGET_CMD=(strace "${STRACE_ARGS[@]}" -- "${TARGET_CMD[@]}")
fi

EXEC_CMD=("bwrap" "${BWRAP_ARGS[@]}" "${ENV_ARGS[@]}" -- "${TARGET_CMD[@]}")

if [ -n "$OPT_MEM" ] || [ -n "$OPT_CPU" ]; then
  if command -v systemd-run >/dev/null 2>&1 && systemd-run --user --scope --quiet -- true 2>/dev/null; then
    SYS_ARGS=(--user --scope --quiet)
    [ -n "$OPT_MEM" ] && SYS_ARGS+=(-p "MemoryMax=$OPT_MEM")
    [ -n "$OPT_CPU" ] && SYS_ARGS+=(-p "CPUQuota=$OPT_CPU")
    exec systemd-run "${SYS_ARGS[@]}" -- "${EXEC_CMD[@]}"
  else
    echo -e "${C_YELLOW}⚠ systemd user scope unavailable — running without cgroup limits${C_RESET}" >&2
  fi
fi

exec "${EXEC_CMD[@]}"
