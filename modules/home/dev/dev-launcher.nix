# ==============================================================================
# dev — On-demand environment launcher & completions
# ==============================================================================
# Fast source-based menus, optional FZF selection and tidy GC-root management.
# Entering a shell still uses `nix develop`; listing environments never evaluates
# the flake.
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

  dev = pkgs.writeShellApplication {
    name = "dev";
    runtimeInputs = with pkgs; [coreutils gnugrep gnused findutils fzf];
    excludeShellChecks = ["SC2016"];
    derivationArgs = {
      LC_ALL = "C.UTF-8";
      LANG = "C.UTF-8";
    };

    text = ''
      ${findFlake}
      if [ ! -f "$FLAKE_PATH/flake.nix" ]; then
        echo "dev: no flake.nix found (tried $FLAKE_PATH, ~/nix-config, ~/projects/nix-config, /etc/nixos)" >&2
        echo "dev: set NIX_CONFIG_FLAKE=/path/to/nix-config to override" >&2
        exit 1
      fi
      FLAKE_PATH="$(cd "$FLAKE_PATH" && pwd -P)"
      SYSTEM="${pkgs.stdenv.hostPlatform.system}"
      ROOT_BASE="$HOME/.local/share/dev-roots"

      _resolve_alias() {
        case "$1" in
          ${aliasCases}
          *) printf '%s\n' "$1" ;;
        esac
      }

      _dev_source() {
        if [ -f "$FLAKE_PATH/shells/$1/default.nix" ]; then
          printf '%s\n' "$FLAKE_PATH/shells/$1/default.nix"
        else
          printf '%s\n' "$FLAKE_PATH/shells/$1.nix"
        fi
      }

      _dev_read_meta() {
        local name="$1" file
        file="$(_dev_source "$name")"
        DEV_ICON="$(sed -n 's/.*icon = "\([^"]*\)".*/\1/p' "$file" 2>/dev/null | head -1)"
        DEV_DESC="$(sed -n 's/.*description = "\([^"]*\)".*/\1/p' "$file" 2>/dev/null | head -1)"
        DEV_ICON="''${DEV_ICON:-📦}"
      }

      _dev_is_kept() {
        [ -L "$ROOT_BASE/$1/profile" ] || [ -L "$ROOT_BASE/$1-profile" ]
      }

      _dev_print_shell() {
        local name="$1" state
        _dev_read_meta "$name"
        if _dev_is_kept "$name"; then
          state="\033[1;32m●\033[0m"
        else
          state="\033[1;30m○\033[0m"
        fi
        printf '  %b  %s  dev %-10s %s\n' "$state" "$DEV_ICON" "$name" "$DEV_DESC"
      }

      _dev_rows() {
        local name state
        for name in ${shellWords}; do
          _dev_read_meta "$name"
          _dev_is_kept "$name" && state="ready" || state="not realised"
          printf '%s\t%s\t%s\t%s\n' "$name" "$DEV_ICON" "$DEV_DESC" "$state"
        done
      }

      _remove_legacy_root() {
        local name="$1"
        rm -f -- "$ROOT_BASE/$name-profile"
        find "$ROOT_BASE" -maxdepth 1 -type l -name "$name-profile-*-link" -delete 2>/dev/null || true
      }

      _list_roots() {
        printf '\033[1;36m╭─ GC-protected devShells\033[0m\n'
        if [ ! -d "$ROOT_BASE" ]; then
          printf '\033[1;36m╰─\033[0m none\n'
          return 0
        fi

        local found=0 dir name generations used
        for dir in "$ROOT_BASE"/*/; do
          [ -d "$dir" ] || continue
          [ -L "$dir/profile" ] || continue
          name="$(basename "$dir")"
          generations="$(find "$dir" -maxdepth 1 -type l -name 'profile-*-link' | wc -l)"
          if [ -f "$dir/last-used" ]; then
            used="$(cat "$dir/last-used")"
          else
            used="unknown"
          fi
          printf '\033[1;36m│\033[0m  \033[1;32m●\033[0m %-12s generations=%-2s last=%s\n' "$name" "$generations" "$used"
          found=1
        done
        [ "$found" -eq 1 ] && printf '\033[1;36m╰─\033[0m root: %s\n' "$ROOT_BASE" || printf '\033[1;36m╰─\033[0m none\n'
      }

      if [ "''${1:-}" = "-h" ] || [ "''${1:-}" = "--help" ]; then
        set --
      fi

      if [ "''${1:-}" = "--roots" ]; then
        _list_roots
        exit 0
      fi

      if [ "''${1:-}" = "--unkeep" ]; then
        [ $# -ge 2 ] || { echo "dev: --unkeep needs an environment name" >&2; exit 1; }
        ENV_NAME="$(_resolve_alias "$2")"
        [[ "$ENV_NAME" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "dev: invalid environment name" >&2; exit 1; }
        [ -f "$(_dev_source "$ENV_NAME")" ] || { echo "dev: unknown environment: $ENV_NAME" >&2; exit 1; }
        rm -rf -- "''${ROOT_BASE:?}/''${ENV_NAME:?}"
        _remove_legacy_root "$ENV_NAME"
        printf '\033[1;32m✓ removed GC root for %s\033[0m\n' "$ENV_NAME"
        exit 0
      fi

      if [ "''${1:-}" = "--unkeep-all" ]; then
        printf 'Remove every devShell GC root in %s? [y/N] ' "$ROOT_BASE"
        read -r reply || reply=""
        case "$reply" in
          [yY]*) rm -rf -- "$ROOT_BASE"; printf '\033[1;32m✓ all devShell roots removed\033[0m\n' ;;
          *) echo "Cancelled." ;;
        esac
        exit 0
      fi

      if [ "''${1:-}" = "-i" ] || [ "''${1:-}" = "--interactive" ]; then
        shift
        [ $# -eq 0 ] || { echo "dev: --interactive does not take an environment name" >&2; exit 1; }
        ENV_NAME="$(_dev_rows | fzf \
          --delimiter=$'\t' --with-nth=2,1,3,4 \
          --height=70% --layout=reverse --border=rounded \
          --prompt='dev > ' | cut -f1 || true)"
        [ -n "$ENV_NAME" ] || exit 0
        set -- "$ENV_NAME"
      fi

      # Fast source-only menu: no `nix eval`, no network and no realisation.
      if [ $# -eq 0 ]; then
        printf '\033[1;36m╭────────────────────────────────────────────────────────────╮\033[0m\n'
        printf '\033[1;36m│ \033[1;35m🚀 On-Demand DevShell Manager                            \033[1;36m│\033[0m\n'
        printf '\033[1;36m╰────────────────────────────────────────────────────────────╯\033[0m\n'
        printf '\033[1;30m  ● GC-protected   ○ not realised   ·   dev -i to select\033[0m\n\n'
        ${menuGroups}
        printf '  aliases: %s\n' ${lib.escapeShellArg menuAliases}
        printf '  \033[1;30mdev -w <env> · dev --roots · dev --unkeep <env>\033[0m\n'
        exit 0
      fi

      # Exact package inspection remains explicit because it evaluates the shell.
      if [ "$1" = "-w" ] || [ "$1" = "--what" ]; then
        shift
        [ $# -ge 1 ] || { echo "dev: -w needs an environment name" >&2; exit 1; }
        ENV_NAME="$(_resolve_alias "$1")"
        echo -e "\033[1;36m🔍 $ENV_NAME\033[0m"

        if ! OUT="$(nix eval --raw \
             "$FLAKE_PATH#devShells.$SYSTEM.$ENV_NAME" \
             --apply 'd:
               let ps = (d.nativeBuildInputs or []) ++ (d.buildInputs or []);
                   names = builtins.map (p: p.name or "?") ps;
                   uniq = builtins.attrNames (builtins.listToAttrs
                            (map (n: { name = n; value = null; }) names));
               in builtins.concatStringsSep "\n" uniq' \
             2>/dev/null)"; then
          echo "dev: cannot inspect $ENV_NAME — is it a real environment?" >&2
          exit 1
        fi
        printf '%s\n' "$OUT" | sed 's/^/  /'
        printf '  \033[1;30m%s packages\033[0m\n' "$(printf '%s\n' "$OUT" | grep -c .)"
        exit 0
      fi

      ENV_NAME="$(_resolve_alias "$1")"
      shift
      [ -f "$(_dev_source "$ENV_NAME")" ] || {
        echo "dev: unknown environment: $ENV_NAME" >&2
        echo "     run 'dev' to list available environments" >&2
        exit 1
      }

      ROOT_DIR="$ROOT_BASE/$ENV_NAME"
      ROOT_PROFILE="$ROOT_DIR/profile"

      _register_root() {
        mkdir -p "$ROOT_DIR"
        if nix print-dev-env "$FLAKE_PATH#$ENV_NAME" \
          --profile "$ROOT_PROFILE" >/dev/null 2>&1; then
          nix profile wipe-history --profile "$ROOT_PROFILE" >/dev/null 2>&1 || true
          date -Is > "$ROOT_DIR/last-used"
          _remove_legacy_root "$ENV_NAME"
        else
          printf '\033[1;33m⚠ could not refresh GC root for %s\033[0m\n' "$ENV_NAME" >&2
        fi
      }

      set +e
      if [ $# -eq 0 ]; then
        printf '\033[1;32m⏳ Launching \033[1;36m%s\033[1;32m (Fish)\033[0m\n' "$ENV_NAME"
        nix develop "$FLAKE_PATH#$ENV_NAME" --command fish
        STATUS=$?
      else
        printf '\033[1;32m⚡ %s: \033[1;33m%s\033[0m\n' "$ENV_NAME" "$*"
        nix develop "$FLAKE_PATH#$ENV_NAME" --command "$@"
        STATUS=$?
      fi
      set -e
      _register_root
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

      complete -c dev -f
      complete -c dev -s i -l interactive -d 'Select an environment with FZF'
      complete -c dev -l roots -d 'List GC-protected environments'
      complete -c dev -l unkeep -x -a '(__dev_shells)' -d 'Remove one GC root'
      complete -c dev -l unkeep-all -d 'Remove every devShell GC root'
      complete -c dev -s h -l help -d 'Show the fast environment menu'
      complete -c dev -n __fish_use_subcommand -a '(__dev_shells)'
      complete -c dev -s w -l what -x -a '(__dev_shells)' -d 'List what is inside'
      complete -c dev -n 'not __fish_use_subcommand; and not __fish_seen_argument -s w -l what' \
          -a '(__fish_complete_command)'
    '';

    devBash = ''
      ${scan}
      _dev_complete() {
        local cur root
        cur="''${COMP_WORDS[COMP_CWORD]}"
        root="''${NIX_CONFIG_FLAKE:-${flakePath}}"
        [ -f "$root/flake.nix" ] || for c in "$HOME/nix-config" "$HOME/projects/nix-config" /etc/nixos; do
          [ -f "$c/flake.nix" ] && { root="$c"; break; }
        done
        mapfile -t COMPREPLY < <(compgen -W "$(__dev_scan "$root" | cut -f1 | tr '\n' ' ') -i --interactive -w --what --roots --unkeep --unkeep-all -h --help" -- "$cur")
      }
      complete -F _dev_complete dev
    '';

    zshDev = ''
      #compdef dev
      _dev() {
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
        shells+=(
          '-i:select with FZF'
          '--interactive:select with FZF'
          '-w:list packages in an environment'
          '--what:list packages in an environment'
          '--roots:list GC-protected environments'
          '--unkeep:remove one GC root'
          '--unkeep-all:remove every GC root'
          '-h:show environment menu'
          '--help:show environment menu'
        )
        _describe 'environment or option' shells
      }
      _dev "$@"
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
