# CLI parsing, source-only menu, and nix develop execution.
{
  pkgs,
  flakePath,
  registry,
  roots,
}: let
  inherit (pkgs) lib;

  shellWords = lib.concatMapStringsSep " " lib.escapeShellArg registry.shellDirs;
  aliasCases = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (alias: target: "${lib.escapeShellArg alias}) printf '%s\\n' ${lib.escapeShellArg target} ;;") registry.aliases
  );
  registeredCases = lib.concatMapStringsSep "\n" (name: "${lib.escapeShellArg name}) return 0 ;;") registry.shellDirs;
  menuAliases = lib.concatStringsSep ", " (
    lib.mapAttrsToList (alias: target: "dev ${alias} → dev ${target}") registry.aliases
  );
  menuGroups =
    lib.concatMapStringsSep "\n" (
      group: let
        memberRows = lib.concatMapStringsSep "\n" (name: "_dev_print_shell ${lib.escapeShellArg name}") group.members;
      in ''
        printf '  \033[1;36m[ %s ]\033[0m\n' ${lib.escapeShellArg group.title}
        ${memberRows}
        printf '\n'
      ''
    )
    registry.groups;

  findFlake = ''
    FLAKE_PATH="''${NIX_CONFIG_FLAKE:-${flakePath}}"
    if [ ! -f "$FLAKE_PATH/flake.nix" ]; then
      for candidate in "$HOME/nix-config" "$HOME/projects/nix-config" "/etc/nixos"; do
        if [ -f "$candidate/flake.nix" ]; then
          FLAKE_PATH="$candidate"
          break
        fi
      done
    fi
  '';

  inherit (roots) rootEnter;
in
  pkgs.writeShellApplication {
    name = "dev";
    runtimeInputs = with pkgs; [coreutils gnugrep gnused findutils fzf nix];
    excludeShellChecks = ["SC2016"];
    derivationArgs = {
      LC_ALL = "C.UTF-8";
      LANG = "C.UTF-8";
    };

    text = ''
      ${findFlake}
      SYSTEM="${pkgs.stdenv.hostPlatform.system}"
      ROOT_BASE="$HOME/.local/share/dev-roots"
      ACTION="launch"
      OPT_INTERACTIVE=0
      OPT_KEEP=1
      OPT_DRY_RUN=0
      OPT_VERBOSE=0
      OPT_SHELL_SET=0
      INTERACTIVE_SHELL="''${DEV_SHELL:-fish}"

      _require_flake() {
        if [ ! -f "$FLAKE_PATH/flake.nix" ]; then
          echo "dev: no flake.nix found (tried $FLAKE_PATH, ~/nix-config, ~/projects/nix-config, /etc/nixos)" >&2
          echo "dev: set NIX_CONFIG_FLAKE=/path/to/nix-config to override" >&2
          exit 1
        fi
        FLAKE_PATH="$(cd "$FLAKE_PATH" && pwd -P)"
      }

      _choose_action() {
        if [ "$ACTION" != "launch" ] && [ "$ACTION" != "$1" ]; then
          echo "dev: conflicting actions: $ACTION and $1" >&2
          exit 1
        fi
        ACTION="$1"
      }

      _resolve_alias() {
        case "$1" in
          ${aliasCases}
          *) printf '%s\n' "$1" ;;
        esac
      }

      _is_registered() {
        case "$1" in
          ${registeredCases}
          *) return 1 ;;
        esac
      }

      ${roots.functions}

      _safe_name() {
        [[ "$1" =~ ^[A-Za-z0-9_-][A-Za-z0-9._-]*$ ]]
      }

      _resolve_interactive_shell() {
        case "$INTERACTIVE_SHELL" in
          fish | bash | zsh) ;;
          current) INTERACTIVE_SHELL="$(basename "''${SHELL:-fish}")" ;;
          *) echo "dev: unsupported interactive shell: $INTERACTIVE_SHELL" >&2; exit 1 ;;
        esac
        command -v "$INTERACTIVE_SHELL" >/dev/null 2>&1 || {
          echo "dev: interactive shell is not available: $INTERACTIVE_SHELL" >&2
          exit 1
        }
      }

      _dev_source() {
        if [ -f "$FLAKE_PATH/shells/$1/default.nix" ]; then
          printf '%s\n' "$FLAKE_PATH/shells/$1/default.nix"
        else
          printf '%s\n' "$FLAKE_PATH/shells/$1.nix"
        fi
      }

      _validate_env() {
        _safe_name "$1" || { echo "dev: invalid environment name: $1" >&2; exit 1; }
        [ -f "$(_dev_source "$1")" ] || {
          echo "dev: unknown environment: $1" >&2
          echo "     run 'dev' to list available environments" >&2
          exit 1
        }
      }

      _dev_read_meta() {
        local name="$1" file
        file="$(_dev_source "$name")"
        DEV_ICON="$(sed -n 's/.*icon = "\([^"]*\)".*/\1/p' "$file" 2>/dev/null | head -1)"
        DEV_DESC="$(sed -n 's/.*description = "\([^"]*\)".*/\1/p' "$file" 2>/dev/null | head -1)"
        DEV_ICON="''${DEV_ICON:-📦}"
      }

      _dev_print_shell() {
        local name="$1"
        _dev_read_meta "$name"
        _root_mark "$name"
        printf '  %b  %s  dev %-10s %s\n' "$ROOT_MARK" "$DEV_ICON" "$name" "$DEV_DESC"
      }

      _dev_rows() {
        local name
        for name in ${shellWords}; do
          _dev_read_meta "$name"
          _root_mark "$name"
          printf '%s\t%s\t%s\t%s\n' "$name" "$DEV_ICON" "$DEV_DESC" "$ROOT_LABEL"
        done
      }

      _print_help() {
        cat <<'EOF'
      Usage:
        dev [OPTIONS] [ENV [COMMAND [ARGS...]]]

      Fast listing and selection:
        dev                       Show the source-only environment menu
        dev -i, --interactive     Select an environment with FZF
        dev -w, --what ENV        Evaluate and list packages in one environment

      GC-root management:
        dev --keep ENV            Realise/refresh the named root without entering
        dev --no-keep ENV ...     Run without creating or refreshing a root
        dev --roots               List existing root state, last use and closure size
        dev --unkeep ENV          Remove one named root, including an orphan
        dev --unkeep-all          Remove every devShell root with confirmation
        dev --prune               Remove directory-only, broken, legacy and orphan roots with confirmation

      Execution controls:
        dev --shell SHELL ENV     Interactive shell: fish, bash, zsh or current
        dev --dry-run ENV ...     Print the resolved plan without evaluating or running
        dev -v, --verbose         Show GC-root and Nix operation details
        dev -h, --help            Show this help

      Aliases: c → build, data → python, default → nix
      Environment: DEV_SHELL selects the default interactive shell; NIX_CONFIG_FLAKE overrides the flake path.
      EOF
      }

      while [ $# -gt 0 ]; do
        case "$1" in
          -h | --help) _choose_action help; shift ;;
          -i | --interactive) OPT_INTERACTIVE=1; shift ;;
          -w | --what) _choose_action what; shift ;;
          --roots) _choose_action roots; shift ;;
          --unkeep) _choose_action unkeep; shift ;;
          --unkeep-all) _choose_action unkeep-all; shift ;;
          --prune) _choose_action prune; shift ;;
          --keep) _choose_action keep; shift ;;
          --no-keep) OPT_KEEP=0; shift ;;
          --shell)
            [ $# -ge 2 ] || { echo "dev: --shell requires fish, bash, zsh or current" >&2; exit 1; }
            INTERACTIVE_SHELL="$2"
            OPT_SHELL_SET=1
            shift 2
            ;;
          --dry-run) OPT_DRY_RUN=1; shift ;;
          -v | --verbose) OPT_VERBOSE=1; shift ;;
          --) shift; break ;;
          -*) echo "dev: unknown option: $1" >&2; exit 1 ;;
          *) break ;;
        esac
      done

      case "$ACTION" in
        help)
          [ $# -eq 0 ] || { echo "dev: --help does not take arguments" >&2; exit 1; }
          _print_help
          exit 0
          ;;
        roots)
          [ $# -eq 0 ] || { echo "dev: --roots does not take arguments" >&2; exit 1; }
          _list_roots
          exit 0
          ;;
        unkeep)
          [ $# -eq 1 ] || { echo "dev: --unkeep needs exactly one root name" >&2; exit 1; }
          ENV_NAME="$(_resolve_alias "$1")"
          _safe_name "$ENV_NAME" || { echo "dev: invalid root name: $ENV_NAME" >&2; exit 1; }
          rm -rf -- "''${ROOT_BASE:?}/$ENV_NAME"
          _remove_legacy_root "$ENV_NAME"
          _forget_stale_indirect_roots
          printf '\033[1;32m✓ removed GC root for %s\033[0m\n' "$ENV_NAME"
          exit 0
          ;;
        unkeep-all)
          [ $# -eq 0 ] || { echo "dev: --unkeep-all does not take arguments" >&2; exit 1; }
          printf 'Remove every devShell GC root in %s? [y/N] ' "$ROOT_BASE"
          read -r reply || reply=""
          case "$reply" in
            [yY]*) rm -rf -- "''${ROOT_BASE:?}"; _forget_stale_indirect_roots; printf '\033[1;32m✓ all devShell roots removed\033[0m\n' ;;
            *) echo "Cancelled." ;;
          esac
          exit 0
          ;;
        prune)
          [ $# -eq 0 ] || { echo "dev: --prune does not take arguments" >&2; exit 1; }
          _prune_roots
          exit 0
          ;;
      esac

      _require_flake

      if [ "$OPT_INTERACTIVE" -eq 1 ]; then
        [ "$ACTION" = "launch" ] || { echo "dev: --interactive cannot be combined with $ACTION" >&2; exit 1; }
        [ $# -eq 0 ] || { echo "dev: --interactive does not take an environment name" >&2; exit 1; }
        ENV_NAME="$(_dev_rows | fzf \
          --delimiter=$'\t' --with-nth=2,1,3,4 \
          --height=70% --layout=reverse --border=rounded \
          --prompt='dev > ' | cut -f1 || true)"
        [ -n "$ENV_NAME" ] || exit 0
        set -- "$ENV_NAME"
      fi

      if [ "$ACTION" = "launch" ] && [ $# -eq 0 ]; then
        if [ "$OPT_DRY_RUN" -eq 1 ] || [ "$OPT_KEEP" -eq 0 ] || [ "$OPT_SHELL_SET" -eq 1 ]; then
          echo "dev: this option combination needs an environment name" >&2
          exit 1
        fi
        printf '\033[1;36m╭────────────────────────────────────────────────────────────╮\033[0m\n'
        printf '\033[1;36m│ \033[1;35m🚀 On-Demand DevShell Manager                            \033[1;36m│\033[0m\n'
        printf '\033[1;36m╰────────────────────────────────────────────────────────────╯\033[0m\n'
        printf '\033[1;30m  ● kept   ◐ directory only   ○ not used   ◆ legacy   ! broken   ·   dev -i to select\033[0m\n\n'
        ${menuGroups}
        printf '  aliases: %s\n' ${lib.escapeShellArg menuAliases}
        printf '  \033[1;30mdev --keep <env> · dev --roots · dev --prune · dev --help\033[0m\n'
        exit 0
      fi

      if [ "$ACTION" = "what" ]; then
        [ $# -eq 1 ] || { echo "dev: -w needs exactly one environment name" >&2; exit 1; }
        ENV_NAME="$(_resolve_alias "$1")"
        _validate_env "$ENV_NAME"
        if [ "$OPT_DRY_RUN" -eq 1 ]; then
          printf 'Action: inspect packages\nFlake:  %s\nShell:  %s\n' "$FLAKE_PATH" "$ENV_NAME"
          exit 0
        fi
        printf '\033[1;36m🔍 %s\033[0m\n' "$ENV_NAME"
        NIX_CMD=(nix)
        [ "$OPT_VERBOSE" -eq 1 ] && NIX_CMD+=(--verbose)
        if ! OUT="$("''${NIX_CMD[@]}" eval --raw \
             "$FLAKE_PATH#devShells.$SYSTEM.$ENV_NAME" \
             --apply 'd:
               let ps = (d.nativeBuildInputs or []) ++ (d.buildInputs or []);
                   names = builtins.map (p: p.name or "?") ps;
                   uniq = builtins.attrNames (builtins.listToAttrs
                            (map (n: { name = n; value = null; }) names));
               in builtins.concatStringsSep "\n" uniq')"; then
          echo "dev: cannot inspect $ENV_NAME" >&2
          exit 1
        fi
        printf '%s\n' "$OUT" | sed 's/^/  /'
        printf '  \033[1;30m%s packages\033[0m\n' "$(printf '%s\n' "$OUT" | grep -c .)"
        exit 0
      fi

      [ $# -ge 1 ] || { echo "dev: missing environment name" >&2; exit 1; }
      ENV_NAME="$(_resolve_alias "$1")"
      shift
      _validate_env "$ENV_NAME"

      if [ "$ACTION" = "keep" ]; then
        [ $# -eq 0 ] || { echo "dev: --keep takes exactly one environment name" >&2; exit 1; }
        [ "$OPT_KEEP" -eq 1 ] || { echo "dev: --keep conflicts with --no-keep" >&2; exit 1; }
        [ "$OPT_SHELL_SET" -eq 0 ] || { echo "dev: --shell cannot be combined with --keep" >&2; exit 1; }
        TARGET_CMD=(true)
        DISPLAY_ACTION="keep only"
      elif [ $# -eq 0 ]; then
        _resolve_interactive_shell
        TARGET_CMD=("$INTERACTIVE_SHELL")
        DISPLAY_ACTION="interactive ($INTERACTIVE_SHELL)"
      else
        [ "$OPT_SHELL_SET" -eq 0 ] || { echo "dev: --shell only applies to interactive sessions" >&2; exit 1; }
        TARGET_CMD=("$@")
        DISPLAY_ACTION="command"
      fi

      ROOT_DIR="$ROOT_BASE/$ENV_NAME"
      ROOT_PROFILE="$ROOT_DIR/profile"
      GC_ROOT="$ROOT_DIR/gc-root"
      LAST_USED="$ROOT_DIR/last-used"

      if [ "$OPT_DRY_RUN" -eq 1 ]; then
        printf 'Action:  %s\n' "$DISPLAY_ACTION"
        printf 'Flake:   %s\n' "$FLAKE_PATH"
        printf 'Shell:   %s\n' "$ENV_NAME"
        printf 'Keep:    %s\n' "$([ "$OPT_KEEP" -eq 1 ] && echo yes || echo no)"
        printf 'Profile: %s\n' "$ROOT_PROFILE"
        printf 'Command:'
        printf ' %q' "''${TARGET_CMD[@]}"
        printf '\n'
        exit 0
      fi

      NIX_CMD=(nix)
      [ "$OPT_VERBOSE" -eq 1 ] && NIX_CMD+=(--verbose)

      if [ "$OPT_KEEP" -eq 1 ]; then
        mkdir -p "$ROOT_DIR"
        _wipe_profile_history "$ROOT_PROFILE" "$ENV_NAME"
        printf '\033[1;32m%s %s (GC-kept)\033[0m\n' \
          "$([ "$ACTION" = "keep" ] && echo '📌 Keeping' || echo '⏳ Launching')" "$ENV_NAME"
        DEVELOP_ARGS=(
          develop --profile "$ROOT_PROFILE" "$FLAKE_PATH#$ENV_NAME"
          --command ${rootEnter}/bin/dev-root-enter
          "$ROOT_PROFILE" "$GC_ROOT" "$LAST_USED" "$ROOT_BASE" "$ENV_NAME" "$OPT_VERBOSE" --
          "''${TARGET_CMD[@]}"
        )
      else
        printf '\033[1;33m⏳ Launching %s without refreshing its GC root\033[0m\n' "$ENV_NAME"
        DEVELOP_ARGS=(develop "$FLAKE_PATH#$ENV_NAME" --command "''${TARGET_CMD[@]}")
      fi

      set +e
      "''${NIX_CMD[@]}" "''${DEVELOP_ARGS[@]}"
      STATUS=$?
      set -e
      exit "$STATUS"
    '';
  }
