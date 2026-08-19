# ==============================================================================
# dev — On-demand environment launcher & completions
# ==============================================================================
# Fast source-based menus, optional FZF selection, direct Nix profiles and
# explicit indirect GC roots. Listing environments never evaluates the flake.
# ==============================================================================
{
  pkgs,
  flakePath,
  ...
}: let
  inherit (pkgs) lib;

  registry = import ../../../shells/registry.nix;
  shellWords = lib.concatMapStringsSep " " lib.escapeShellArg registry.shellDirs;

  bashAliasRows = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (alias: target: "printf '${alias}\\t↪\\talias for ${target}\\n'") registry.aliases
  );
  fishAliasRows = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (alias: target: "printf '${alias}\\t↪ alias for ${target}\\n'") registry.aliases
  );
  zshAliasRows = lib.concatStringsSep " " (
    lib.mapAttrsToList (alias: target: "'${alias}:alias for ${target}'") registry.aliases
  );
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

  # Runs inside `nix develop`, after --profile has selected the new current
  # generation but before the user's shell/command. The explicit indirect root
  # is what makes an arbitrary profile path a real GC root.
  rootEnter = pkgs.writeShellApplication {
    name = "dev-root-enter";
    runtimeInputs = with pkgs; [coreutils findutils nix];
    text = ''
      [ $# -ge 7 ] || { echo "dev-root-enter: invalid invocation" >&2; exit 2; }
      profile="$1"
      gc_root="$2"
      last_used="$3"
      root_base="$4"
      env_name="$5"
      verbose="$6"
      shift 6
      [ "$1" = "--" ] || { echo "dev-root-enter: missing command separator" >&2; exit 2; }
      shift
      [ $# -ge 1 ] || { echo "dev-root-enter: missing target command" >&2; exit 2; }

      target="$(readlink -f -- "$profile" 2>/dev/null || true)"
      case "$target" in
        /nix/store/*) ;;
        *) echo "dev: profile for $env_name does not resolve into /nix/store" >&2; exit 1 ;;
      esac
      [ -e "$target" ] || { echo "dev: profile target is missing: $target" >&2; exit 1; }

      if [ "$verbose" -eq 1 ]; then
        printf 'dev: registering indirect GC root %s -> %s\n' "$gc_root" "$target" >&2
        nix-store --add-root "$gc_root" --indirect --realise "$target" >/dev/null
      else
        error="$(nix-store --add-root "$gc_root" --indirect --realise "$target" 2>&1)" || {
          printf 'dev: cannot register GC root for %s\n%s\n' "$env_name" "$error" >&2
          exit 1
        }
      fi

      # --profile creates generations. Keep only the current one so a shell has
      # one stable root instead of an ever-growing history.
      if [ "$verbose" -eq 1 ]; then
        nix profile wipe-history --profile "$profile" || true
      else
        nix profile wipe-history --profile "$profile" >/dev/null 2>&1 || \
          printf 'dev: warning: could not wipe old profile history for %s\n' "$env_name" >&2
      fi

      date -Is > "$last_used"
      rm -f -- "$root_base/$env_name-profile"
      find "$root_base" -maxdepth 1 -type l -name "$env_name-profile-*-link" -delete 2>/dev/null || true

      exec "$@"
    '';
  };

  dev = pkgs.writeShellApplication {
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
      GC_ROOTS=""
      GC_ROOTS_LOADED=0
      GC_ROOTS_OK=0

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

      _load_gc_roots() {
        if [ "$GC_ROOTS_LOADED" -eq 1 ]; then
          [ "$GC_ROOTS_OK" -eq 1 ]
          return
        fi

        GC_ROOTS_LOADED=1
        if GC_ROOTS="$(nix-store --gc --print-roots 2>/dev/null)"; then
          GC_ROOTS_OK=1
          return 0
        fi

        GC_ROOTS=""
        GC_ROOTS_OK=0
        return 1
      }

      _root_is_daemon_registered() {
        local root="$1"
        [ "$GC_ROOTS_OK" -eq 1 ] && grep -Fq "$root -> " <<< "$GC_ROOTS"
      }

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

      _root_state() {
        local name="$1" dir="$ROOT_BASE/$1"
        if [ -L "$dir/gc-root" ]; then
          if [ ! -e "$dir/gc-root" ]; then
            printf 'broken\n'
          elif [ "$GC_ROOTS_OK" -ne 1 ]; then
            printf 'unknown\n'
          elif _root_is_daemon_registered "$dir/gc-root"; then
            printf 'kept\n'
          else
            printf 'unregistered\n'
          fi
        elif [ -e "$dir/gc-root" ]; then
          printf 'broken\n'
        elif [ -L "$ROOT_BASE/$name-profile" ]; then
          [ -e "$ROOT_BASE/$name-profile" ] && printf 'legacy\n' || printf 'broken\n'
        elif [ -d "$dir" ]; then
          printf 'stale\n'
        else
          printf 'missing\n'
        fi
      }

      _root_closure_size() {
        local dir="$1" target line size
        [ -L "$dir/gc-root" ] && [ -e "$dir/gc-root" ] || {
          printf 'unknown\n'
          return 0
        }
        target="$(readlink -f -- "$dir/gc-root" 2>/dev/null || true)"
        [ -n "$target" ] || {
          printf 'unknown\n'
          return 0
        }
        line="$(nix path-info -Sh "$target" 2>/dev/null || true)"
        size="$(printf '%s\n' "$line" | sed -n '1{s/^[^[:space:]]*[[:space:]]*//;p;}')"
        printf '%s\n' "''${size:-unknown}"
      }

      _root_mark() {
        case "$(_root_state "$1")" in
          kept) ROOT_MARK="\033[1;32m●\033[0m"; ROOT_LABEL="kept" ;;
          legacy) ROOT_MARK="\033[1;33m◆\033[0m"; ROOT_LABEL="legacy" ;;
          unregistered) ROOT_MARK="\033[1;31m!\033[0m"; ROOT_LABEL="unregistered" ;;
          broken | stale) ROOT_MARK="\033[1;31m!\033[0m"; ROOT_LABEL="broken" ;;
          unknown) ROOT_MARK="\033[1;33m?\033[0m"; ROOT_LABEL="unknown" ;;
          *) ROOT_MARK="\033[1;30m○\033[0m"; ROOT_LABEL="not kept" ;;
        esac
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

      _remove_legacy_root() {
        local name="$1"
        rm -f -- "$ROOT_BASE/$name-profile"
        find "$ROOT_BASE" -maxdepth 1 -type l -name "$name-profile-*-link" -delete 2>/dev/null || true
      }

      _forget_stale_indirect_roots() {
        if ! nix-store --gc --print-roots >/dev/null 2>&1; then
          echo "dev: roots were removed, but the Nix daemon could not refresh its indirect-root registry" >&2
          return 1
        fi
      }

      _list_roots() {
        printf '\033[1;36m╭─ GC-protected devShells\033[0m\n'
        if [ ! -d "$ROOT_BASE" ]; then
          printf '\033[1;36m╰─\033[0m none\n'
          return 0
        fi

        if ! _load_gc_roots; then
          printf '\033[1;33m│\033[0m  ? Nix daemon root registry unavailable; registration states are unknown\n' >&2
        fi

        local found=0 dir name state generations used registered label mark closure_size
        for dir in "$ROOT_BASE"/*/; do
          dir="''${dir%/}"
          if [ ! -d "$dir" ] || [ -L "$dir" ]; then continue; fi
          name="$(basename "$dir")"
          state="$(_root_state "$name")"
          [ "$state" != "missing" ] || continue
          generations="$(find "$dir" -maxdepth 1 -type l -name 'profile-*-link' | wc -l | tr -d ' ')"
          used="unknown"
          [ -f "$dir/last-used" ] && used="$(cat "$dir/last-used")"
          _is_registered "$name" && registered=1 || registered=0

          if [ "$registered" -eq 0 ]; then
            mark="\033[1;33m◆\033[0m"; label="orphan"
          elif [ "$state" = "kept" ]; then
            mark="\033[1;32m●\033[0m"; label="kept"
          elif [ "$state" = "unknown" ]; then
            mark="\033[1;33m?\033[0m"; label="unknown"
          else
            mark="\033[1;31m!\033[0m"; label="$state"
          fi
          closure_size="$(_root_closure_size "$dir")"
          printf '\033[1;36m│\033[0m  %b %-12s %-12s generations=%-2s closure=%-10s last=%s\n' \
            "$mark" "$name" "$label" "$generations" "$closure_size" "$used"
          found=1
        done

        local legacy legacy_name
        for legacy in "$ROOT_BASE"/*-profile; do
          [ -L "$legacy" ] || continue
          legacy_name="$(basename "$legacy")"
          legacy_name="''${legacy_name%-profile}"
          printf '\033[1;36m│\033[0m  \033[1;33m◆\033[0m %-12s legacy       path=%s\n' "$legacy_name" "$legacy"
          found=1
        done

        if [ "$found" -eq 1 ]; then
          printf '\033[1;36m╰─\033[0m root: %s\n' "$ROOT_BASE"
          printf '   closure sizes include shared store paths and are not additive.\n'
        else
          printf '\033[1;36m╰─\033[0m none\n'
        fi
      }

      _prune_roots() {
        if [ ! -d "$ROOT_BASE" ]; then
          echo "dev: no root directory to prune"
          return 0
        fi

        if ! _load_gc_roots; then
          echo "dev: cannot query the Nix daemon root registry; prune aborted without changes" >&2
          return 1
        fi

        local -a prune_dirs=() prune_legacy=()
        local dir name state reason legacy legacy_name
        for dir in "$ROOT_BASE"/*/; do
          dir="''${dir%/}"
          if [ ! -d "$dir" ] || [ -L "$dir" ]; then continue; fi
          name="$(basename "$dir")"
          state="$(_root_state "$name")"
          reason=""
          if ! _is_registered "$name"; then
            reason="orphan"
          elif [ "$state" != "kept" ]; then
            reason="$state"
          fi
          if [ -n "$reason" ]; then
            prune_dirs+=("$dir")
            printf '  remove %-12s (%s)\n' "$name" "$reason"
          fi
        done
        for legacy in "$ROOT_BASE"/*-profile; do
          [ -L "$legacy" ] || continue
          legacy_name="$(basename "$legacy")"
          legacy_name="''${legacy_name%-profile}"
          prune_legacy+=("$legacy_name")
          printf '  remove %-12s (legacy)\n' "$legacy_name"
        done

        if [ "''${#prune_dirs[@]}" -eq 0 ] && [ "''${#prune_legacy[@]}" -eq 0 ]; then
          echo "dev: no orphaned, broken or legacy roots"
          return 0
        fi

        printf 'Prune the roots listed above? [y/N] '
        read -r reply || reply=""
        case "$reply" in
          [yY]*) ;;
          *) echo "Cancelled."; return 0 ;;
        esac

        for dir in "''${prune_dirs[@]}"; do
          rm -rf -- "$dir"
        done
        for name in "''${prune_legacy[@]}"; do
          _remove_legacy_root "$name"
        done
        _forget_stale_indirect_roots
        printf '\033[1;32m✓ stale devShell roots pruned\033[0m\n'
      }

      _wipe_profile_history() {
        local profile="$1" name="$2"
        [ -L "$profile" ] || return 0
        if [ "$OPT_VERBOSE" -eq 1 ]; then
          nix profile wipe-history --profile "$profile" || true
        else
          nix profile wipe-history --profile "$profile" >/dev/null 2>&1 || \
            printf 'dev: warning: could not wipe old profile history for %s\n' "$name" >&2
        fi
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
        dev --roots               List registration, last use and closure size for every root
        dev --unkeep ENV          Remove one named root, including an orphan
        dev --unkeep-all          Remove every devShell root with confirmation
        dev --prune               Remove broken, legacy and orphan roots with confirmation

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

      # The fast menu remains evaluation-free, but reads the daemon's root list
      # once so a plain symlink is never presented as GC-protected.
      if [ "$OPT_INTERACTIVE" -eq 1 ] || { [ "$ACTION" = "launch" ] && [ $# -eq 0 ]; }; then
        _load_gc_roots || true
      fi

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
        printf '\033[1;30m  ● kept   ○ not kept   ◆ legacy   ! broken/unregistered   ? unknown   ·   dev -i to select\033[0m\n\n'
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
  };

  completions = let
    scan = ''
      __dev_scan() {
        local root="$1" file n icon desc
        for n in ${shellWords}; do
          file="$root/shells/$n/default.nix"
          [ -f "$file" ] || file="$root/shells/$n.nix"
          icon="$(sed -n 's/.*icon = "\([^"]*\)".*/\1/p' "$file" 2>/dev/null | head -1)"
          desc="$(sed -n 's/.*description = "\([^"]*\)".*/\1/p' "$file" 2>/dev/null | head -1)"
          printf '%s\t%s\t%s\n' "$n" "''${icon:-📦}" "$desc"
        done
        ${bashAliasRows}
      }
      __dev_roots() {
        local d
        for d in "$HOME/.local/share/dev-roots"/*/; do
          d="''${d%/}"
          [ -d "$d" ] && [ ! -L "$d" ] && basename "$d"
        done
      }
    '';

    devFish = ''
      function __dev_flake
          test -n "$NIX_CONFIG_FLAKE"; and echo $NIX_CONFIG_FLAKE; and return
          for c in ${flakePath} $HOME/nix-config $HOME/projects/nix-config /etc/nixos
              test -f $c/flake.nix; and echo $c; and return
          end
      end

      function __dev_shells
          set -l root (__dev_flake)
          test -n "$root"; or return 0
          for n in ${shellWords}
              set -l file $root/shells/$n/default.nix
              test -f $file; or set file $root/shells/$n.nix
              set -l icon (sed -n 's/.*icon = "\([^"]*\)".*/\1/p' $file 2>/dev/null | head -1)
              set -l desc (sed -n 's/.*description = "\([^"]*\)".*/\1/p' $file 2>/dev/null | head -1)
              printf '%s\t%s %s\n' $n "$icon" "$desc"
          end
          ${fishAliasRows}
      end

      function __dev_roots
          for d in $HOME/.local/share/dev-roots/*/
              set d (string replace -r '/$' "" -- $d)
              if test -d "$d"; and not test -L "$d"
                  basename "$d"
              end
          end
      end

      complete -c dev -f
      complete -c dev -s i -l interactive -d 'Select an environment with FZF'
      complete -c dev -s w -l what -x -a '(__dev_shells)' -d 'List packages in an environment'
      complete -c dev -l keep -x -a '(__dev_shells)' -d 'Refresh one GC root without entering'
      complete -c dev -l no-keep -d 'Run without refreshing a GC root'
      complete -c dev -l roots -d 'List GC-protected environments'
      complete -c dev -l unkeep -x -a '(__dev_roots)' -d 'Remove one GC root'
      complete -c dev -l unkeep-all -d 'Remove every devShell GC root'
      complete -c dev -l prune -d 'Remove broken, legacy and orphan roots'
      complete -c dev -l shell -x -a 'fish bash zsh current' -d 'Choose the interactive shell'
      complete -c dev -l dry-run -d 'Print the resolved plan only'
      complete -c dev -s v -l verbose -d 'Show Nix and GC-root details'
      complete -c dev -s h -l help -d 'Show usage and options'
      complete -c dev -n __fish_use_subcommand -a '(__dev_shells)'
      complete -c dev -n 'not __fish_use_subcommand; and not __fish_seen_argument -s w -l what -l keep -l unkeep' \
          -a '(__fish_complete_command)'
    '';

    devBash = ''
      ${scan}
      _dev_complete() {
        local cur prev root words roots
        cur="''${COMP_WORDS[COMP_CWORD]}"
        prev="''${COMP_WORDS[COMP_CWORD-1]:-}"
        root="''${NIX_CONFIG_FLAKE:-${flakePath}}"
        [ -f "$root/flake.nix" ] || for c in "$HOME/nix-config" "$HOME/projects/nix-config" /etc/nixos; do
          [ -f "$c/flake.nix" ] && { root="$c"; break; }
        done
        words="$(__dev_scan "$root" | cut -f1 | tr '\n' ' ')"
        roots="$(__dev_roots | tr '\n' ' ')"

        case "$prev" in
          --shell) mapfile -t COMPREPLY < <(compgen -W 'fish bash zsh current' -- "$cur"); return ;;
          -w | --what | --keep) mapfile -t COMPREPLY < <(compgen -W "$words" -- "$cur"); return ;;
          --unkeep) mapfile -t COMPREPLY < <(compgen -W "$roots" -- "$cur"); return ;;
        esac

        local i token have_env=0 skip=0
        for ((i=1; i<COMP_CWORD; i++)); do
          token="''${COMP_WORDS[i]}"
          [ "$skip" -eq 1 ] && { skip=0; continue; }
          case "$token" in
            --shell) skip=1 ;;
            -i | --interactive | -w | --what | --keep | --no-keep | --roots | --unkeep | --unkeep-all | --prune | --dry-run | -v | --verbose | -h | --help) ;;
            -*) ;;
            *) have_env=1; break ;;
          esac
        done

        if [ "$have_env" -eq 1 ]; then
          mapfile -t COMPREPLY < <(compgen -c -- "$cur")
        else
          mapfile -t COMPREPLY < <(compgen -W "$words -i --interactive -w --what --keep --no-keep --roots --unkeep --unkeep-all --prune --shell --dry-run -v --verbose -h --help" -- "$cur")
        fi
      }
      complete -F _dev_complete dev
    '';

    zshDev = ''
      #compdef dev
      _dev_shells() {
        local root="''${NIX_CONFIG_FLAKE:-${flakePath}}"
        [[ -f "$root/flake.nix" ]] || for c in "$HOME/nix-config" "$HOME/projects/nix-config" /etc/nixos; do
          [[ -f "$c/flake.nix" ]] && { root="$c"; break; }
        done
        local -a shells
        local n file desc
        for n in ${shellWords}; do
          file="$root/shells/$n/default.nix"
          [[ -f "$file" ]] || file="$root/shells/$n.nix"
          desc="$(sed -n 's/.*description = "\([^"]*\)".*/\1/p' "$file" 2>/dev/null | head -1)"
          shells+=("$n:$desc")
        done
        shells+=(${zshAliasRows})
        _describe 'environment' shells
      }

      _dev_roots() {
        local -a roots
        local d
        for d in "$HOME/.local/share/dev-roots"/*/(N/); do
          [[ -L "''${d%/}" ]] && continue
          roots+=("''${''${d%/}:t}")
        done
        _describe 'GC root' roots
      }

      _arguments -C \
        '(-i --interactive)'{-i,--interactive}'[select with FZF]' \
        '(-w --what)'{-w,--what}'[list packages]:environment:->envs' \
        '--keep[refresh a GC root without entering]:environment:->envs' \
        '--no-keep[run without refreshing a GC root]' \
        '--roots[list GC roots]' \
        '--unkeep[remove one GC root]:root:->roots' \
        '--unkeep-all[remove every GC root]' \
        '--prune[remove broken, legacy and orphan roots]' \
        '--shell[choose interactive shell]:shell:(fish bash zsh current)' \
        '--dry-run[print the resolved plan only]' \
        '(-v --verbose)'{-v,--verbose}'[show Nix and GC-root details]' \
        '(-h --help)'{-h,--help}'[show usage and options]' \
        '1:environment:->envs' \
        '*::command:_normal'
      case "$state" in
        envs) _dev_shells ;;
        roots) _dev_roots ;;
      esac
    '';
  in
    pkgs.runCommand "dev-completions" {} ''
      install -Dm444 ${pkgs.writeText "dev.fish" devFish} \
        $out/share/fish/vendor_completions.d/dev.fish
      install -Dm444 ${pkgs.writeText "dev" devBash} \
        $out/share/bash-completion/completions/dev
      install -Dm444 ${pkgs.writeText "_dev" zshDev} \
        $out/share/zsh/site-functions/_dev
    '';
in {
  home.packages = [dev completions];
  programs.fish.enable = lib.mkDefault true;
}
