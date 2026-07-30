# ==============================================================================
# dev — launcher for the on-demand shells in shells/
# ==============================================================================
# Split out of nix-tools.nix, which had become a package list with a hundred
# lines of shell wedged into the middle of it.
#
# ── Two sources of truth, deliberately ──────────────────────────────────────
# The menu reads `devShellsMeta` through `nix eval`: authoritative, grouped,
# and correct about aliases and composites like `test`.
#
# Tab completion cannot do that. `nix eval` on a cold cache takes seconds, and
# a completion that stalls the terminal is worse than no completion. So it
# reads shells/*/ directly with grep — 43 ms measured, no nix, no evaluation.
#
# The duplication is real and bounded: the directory listing can only be wrong
# about `test` and `c`, which are handled explicitly below. Everything else in
# shells/ is a directory whose name is the shell's name, and the registry
# asserts that anyway.
# ==============================================================================
{
  pkgs,
  flakePath,
  ...
}: let
  inherit (pkgs) lib;

  # Shared by the launcher and the completions so they cannot disagree about
  # where the flake is.
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
    runtimeInputs = with pkgs; [jq coreutils gnugrep gnused findutils];

    # The banner and the menu are full of escapes and box-drawing characters
    # that shellcheck reads as suspicious. SC2016 fires on the jq programs,
    # where single quotes are exactly right.
    excludeShellChecks = ["SC2016"];

    # shellcheck encodes its report through the locale; under the C locale of
    # a build sandbox it cannot print the box characters below and dies with
    # `commitBuffer: invalid argument` instead of the finding itself.
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

      # ── the menu ─────────────────────────────────────────────────────────
      if [ $# -eq 0 ]; then
        echo -e "\033[1;36m╭────────────────────────────────────────────────────────────╮\033[0m"
        echo -e "\033[1;36m│ \033[1;35m🚀 On-Demand DevShell Manager                            \033[1;36m│\033[0m"
        echo -e "\033[1;36m╰────────────────────────────────────────────────────────────╯\033[0m"
        echo -e "\033[1;36m💡 Usage: dev <environment> [command...]   ·   dev -w <env> to inspect\033[0m"
        echo -e "\033[1;33m📦 Environments in $FLAKE_PATH:\033[0m"
        echo
        if META="$(nix eval --json "$FLAKE_PATH#devShells.$SYSTEM.devShellsMeta" 2>/dev/null)"; then
          printf '%s' "$META" | jq -r '
            (.shells + .extra) as $all
            | ( .groups[]
              | "  [ \(.title) ]",
                ( .members[]
                  | select($all[.] != null)
                  | "  \($all[.].icon // "📦")  dev \(. + "            "
                      | .[0:12])  \($all[.].description // "")"
                ),
                ""
              ),
              ( ($all | keys) - ([.groups[].members] | flatten) ) as $rest
              | select(($rest | length) > 0)
              | "  [ Other ]",
                ( $rest[] | "  \($all[.].icon // "📦")  dev \(. + "            " | .[0:12])  \($all[.].description // "")" ),
                ""
          '
          printf '%s' "$META" | jq -r '
            "  aliases: " + ([.aliases | to_entries[] | "dev \(.key) → dev \(.value)"] | join(", "))
          '
        else
          # Fallback when metadata cannot be evaluated (older checkout, or an
          # error in the flake): list directories rather than printing nothing.
          echo "  (metadata unavailable — listing shell directories)"
          for d in "$FLAKE_PATH"/shells/*/; do
            n="$(basename "$d")"
            case "$n" in _*) continue ;; esac
            echo "  - dev $n"
          done
        fi
        exit 0
      fi

      # ── -w / --what: what is actually in a shell ─────────────────────────
      # `dev python` then `which -a` was the old way to answer "does this have
      # ruff?", and it costs a full shell evaluation plus a subshell to leave.
      # This reads the package list out of the built shell instead.
      if [ "$1" = "-w" ] || [ "$1" = "--what" ]; then
        shift
        [ $# -ge 1 ] || { echo "dev: -w needs an environment name" >&2; exit 1; }
        ENV_NAME="$1"

        echo -e "\033[1;36m🔍 $ENV_NAME\033[0m"

        # nativeBuildInputs, not buildInputs. mkShell puts its `packages`
        # argument in the former (pkgs/build-support/mkshell/default.nix:
        # `nativeBuildInputs = packages ++ …`); buildInputs only receives what
        # comes through `inputsFrom`. Reading the wrong one prints nothing for
        # every shell here and a full list for `test`, which is a confusing
        # way to be wrong.
        #
        # Both are read and merged, so composites are complete.
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
          echo "     (dev with no arguments lists them)" >&2
          exit 1
        fi
        printf '%s\n' "$OUT" | sed 's/^/  /'
        printf '  \033[1;30m%s packages\033[0m\n' "$(printf '%s\n' "$OUT" | grep -c .)"
        exit 0
      fi

      ENV_NAME="$1"
      shift

      mkdir -p "$HOME/.local/share/dev-roots"
      ROOT_PROFILE="$HOME/.local/share/dev-roots/$ENV_NAME-profile"

      # The GC root is registered AFTER the shell exits, not concurrently with
      # it. Running `nix print-dev-env` in the background while `nix develop`
      # evaluates makes both processes write to the same eval cache, which
      # produces:
      #   error (ignored): SQLite database '…/eval-cache-v6/….sqlite' is busy
      # Harmless, but it printed on every single `dev` invocation. Sequencing
      # them removes the contention, and by then the evaluation is cached so
      # registering the root is nearly instant.
      _register_root() {
        nix print-dev-env "$FLAKE_PATH#$ENV_NAME" \
          --profile "$ROOT_PROFILE" >/dev/null 2>&1 || true
      }

      if [ $# -eq 0 ]; then
        echo -e "\033[1;32m⏳ Evaluating & launching On-Demand DevShell: \033[1;36m$ENV_NAME \033[1;32m(Default shell: Fish)\033[0m"
        nix develop "$FLAKE_PATH#$ENV_NAME" --command fish
        STATUS=$?
      else
        echo -e "\033[1;32m⚡ Executing task inside On-Demand DevShell \033[1;36m$ENV_NAME\033[1;32m: \033[1;33m$*\033[0m"
        nix develop "$FLAKE_PATH#$ENV_NAME" --command fish -c "$*"
        STATUS=$?
      fi
      _register_root
      exit $STATUS
    '';
  };

  # ── completions ─────────────────────────────────────────────────────────────
  # Read shells/*/ at completion time rather than asking nix, because a Tab
  # that takes two seconds is a Tab nobody presses twice. Measured at 43 ms
  # including the greps for icon and description.
  #
  # `test` and `c` are the only names in devShellsMeta that are not directories,
  # so they are the only two that have to be named here. If a third composite
  # is ever added, this list is where it goes — and the menu will show it
  # regardless, so the failure is a missing completion rather than a lie.
  completions = let
    scan = ''
      # Emits "name<TAB>icon<TAB>description" for each shell directory.
      __dev_scan() {
        local root="$1" d n icon desc
        for d in "$root"/shells/*/; do
          [ -d "$d" ] || continue
          n="$(basename "$d")"
          case "$n" in _*) continue ;; esac
          icon="$(sed -n 's/.*icon = "\([^"]*\)".*/\1/p' "$d/default.nix" 2>/dev/null | head -1)"
          desc="$(sed -n 's/.*description = "\([^"]*\)".*/\1/p' "$d/default.nix" 2>/dev/null | head -1)"
          printf '%s\t%s\t%s\n' "$n" "''${icon:-📦}" "$desc"
        done
        printf 'test\t🧪\tComposite: Python + Rust toolchains\n'
        printf 'c\t🛠️\talias for build\n'
      }
    '';

    fish = ''
      # GENERATED by modules/home/dev/dev-launcher.nix — do not edit.
      function __dev_flake
          test -n "$NIX_CONFIG_FLAKE"; and echo $NIX_CONFIG_FLAKE; and return
          for c in ${flakePath} $HOME/nix-config $HOME/projects/nix-config /etc/nixos
              test -f $c/flake.nix; and echo $c; and return
          end
      end

      function __dev_shells
          set -l root (__dev_flake)
          test -n "$root"; or return 0
          for d in $root/shells/*/
              set -l n (basename $d)
              string match -q '_*' $n; and continue
              set -l icon (sed -n 's/.*icon = "\([^"]*\)".*/\1/p' $d/default.nix 2>/dev/null | head -1)
              set -l desc (sed -n 's/.*description = "\([^"]*\)".*/\1/p' $d/default.nix 2>/dev/null | head -1)
              printf '%s\t%s %s\n' $n "$icon" "$desc"
          end
          printf 'test\t🧪 Composite: Python + Rust toolchains\n'
          printf 'c\t🛠️ alias for build\n'
      end

      # No file completion for the first argument: it is always a shell name.
      complete -c dev -f
      complete -c dev -n __fish_use_subcommand -a '(__dev_shells)'
      complete -c dev -s w -l what -x -a '(__dev_shells)' -d 'list what is inside'

      # After the shell name comes a command to run inside it, so hand back to
      # ordinary command completion rather than offering shell names again.
      #
      # __fish_complete_command, not __fish_complete_subcommand: the latter is
      # for wrappers like `sudo` that take a full command line as their tail,
      # and it returns nothing here. Both names exist and only one works.
      complete -c dev -n 'not __fish_use_subcommand; and not __fish_seen_argument -s w -l what' \
          -a '(__fish_complete_command)'
    '';

    bash = ''
      # GENERATED by modules/home/dev/dev-launcher.nix — do not edit.
      ${scan}
      _dev_complete() {
        local cur root
        cur="''${COMP_WORDS[COMP_CWORD]}"
        root="''${NIX_CONFIG_FLAKE:-${flakePath}}"
        [ -f "$root/flake.nix" ] || for c in "$HOME/nix-config" "$HOME/projects/nix-config" /etc/nixos; do
          [ -f "$c/flake.nix" ] && { root="$c"; break; }
        done

        # Only the first argument (or the one after -w) is a shell name.
        if [ "$COMP_CWORD" -gt 1 ] && [ "''${COMP_WORDS[1]}" != "-w" ] && [ "''${COMP_WORDS[1]}" != "--what" ]; then
          mapfile -t COMPREPLY < <(compgen -c -- "$cur")
          return
        fi

        mapfile -t COMPREPLY < <(compgen -W "$(__dev_scan "$root" | cut -f1 | tr '\n' ' ') -w --what" -- "$cur")
      }
      complete -F _dev_complete dev
    '';

    zsh = ''
      #compdef dev
      # GENERATED by modules/home/dev/dev-launcher.nix — do not edit.
      _dev() {
        local root="''${NIX_CONFIG_FLAKE:-${flakePath}}"
        [[ -f "$root/flake.nix" ]] || for c in "$HOME/nix-config" "$HOME/projects/nix-config" /etc/nixos; do
          [[ -f "$c/flake.nix" ]] && { root="$c"; break; }
        done

        if (( CURRENT > 2 )) && [[ "''${words[2]}" != "-w" && "''${words[2]}" != "--what" ]]; then
          _command_names -e
          return
        fi

        local -a shells
        local d n desc
        for d in "$root"/shells/*/(N/); do
          n="''${''${d%/}:t}"
          [[ "$n" == _* ]] && continue
          desc="$(sed -n 's/.*description = "\([^"]*\)".*/\1/p' "$d/default.nix" 2>/dev/null | head -1)"
          shells+=("$n:$desc")
        done
        shells+=('test:Composite: Python + Rust toolchains' 'c:alias for build')
        _describe 'environment' shells
      }
      _dev "$@"
    '';
  in
    pkgs.runCommand "dev-completions" {} ''
      install -Dm444 ${pkgs.writeText "dev.fish" fish} \
        $out/share/fish/vendor_completions.d/dev.fish
      install -Dm444 ${pkgs.writeText "dev.bash" bash} \
        $out/share/bash-completion/completions/dev
      install -Dm444 ${pkgs.writeText "_dev" zsh} \
        $out/share/zsh/site-functions/_dev
    '';
in {
  # Both go in home.packages, so the completion files land in the home-manager
  # profile's share/ — which IS on XDG_DATA_DIRS for a login shell. That is the
  # difference from a devShell, where nothing puts a package's share/ there and
  # the files sit in the store unread.
  #
  # In other words: this works from the moment you log in, with no `exec fish`.
  home.packages = [dev completions];

  # Completions are only autoloaded for a command fish can see, and the file
  # has to be found at startup. Both hold here because `dev` is installed at
  # the profile level rather than entered into.
  programs.fish.enable = lib.mkDefault true;
}
