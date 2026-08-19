# GC-root registration and lifecycle helpers for the dev launcher.
{pkgs}: let
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

  functions = ''
      _root_state() {
        local name="$1" dir="$ROOT_BASE/$1" target
        if [ -L "$dir/gc-root" ]; then
          # Registration is performed synchronously by dev-root-enter. A live
          # local link into /nix/store therefore represents the normal kept
          # state without a second, slow daemon-wide query on every menu.
          target="$(readlink -f -- "$dir/gc-root" 2>/dev/null || true)"
          case "$target" in
            /nix/store/*) [ -e "$target" ] && printf 'kept\n' || printf 'broken\n' ;;
            *) printf 'broken\n' ;;
          esac
        elif [ -e "$dir/gc-root" ]; then
          printf 'broken\n'
        elif [ -L "$ROOT_BASE/$name-profile" ]; then
          [ -e "$ROOT_BASE/$name-profile" ] && printf 'legacy\n' || printf 'broken\n'
        elif [ -d "$dir" ]; then
          printf 'directory\n'
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
          directory) ROOT_MARK="\033[1;33m◐\033[0m"; ROOT_LABEL="directory only" ;;
          legacy) ROOT_MARK="\033[1;33m◆\033[0m"; ROOT_LABEL="legacy" ;;
          broken) ROOT_MARK="\033[1;31m!\033[0m"; ROOT_LABEL="broken" ;;
          *) ROOT_MARK="\033[1;30m○\033[0m"; ROOT_LABEL="not used" ;;
        esac
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
        printf '\033[1;36m╭─ DevShell root state\033[0m\n'
        if [ ! -d "$ROOT_BASE" ]; then
          printf '\033[1;36m╰─\033[0m none\n'
          return 0
        fi

        local found=0 dir name generations used registered label mark closure_size
        for dir in "$ROOT_BASE"/*/; do
          dir="''${dir%/}"
          if [ ! -d "$dir" ] || [ -L "$dir" ]; then continue; fi
          name="$(basename "$dir")"
          generations="$(find "$dir" -maxdepth 1 -type l -name 'profile-*-link' | wc -l | tr -d ' ')"
          used="unknown"
          [ -f "$dir/last-used" ] && used="$(cat "$dir/last-used")"
          _is_registered "$name" && registered=1 || registered=0
          _root_mark "$name"

          if [ "$registered" -eq 0 ]; then
            mark="\033[1;33m◆\033[0m"; label="orphan"
          else
            mark="$ROOT_MARK"; label="$ROOT_LABEL"
          fi
          closure_size="$(_root_closure_size "$dir")"
          printf '\033[1;36m│\033[0m  %b %-12s %-14s generations=%-2s closure=%-10s last=%s\n' \
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
          else
            case "$state" in
              kept) ;;
              directory) reason="directory-only" ;;
              *) reason="$state" ;;
            esac
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
          echo "dev: no directory-only, orphaned, broken or legacy roots"
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
        printf '\033[1;32m✓ obsolete devShell root directories pruned\033[0m\n'
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
  '';
in {
  inherit rootEnter functions;
}
