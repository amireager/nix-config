# ==============================================================================
# dev & box — Launchers & Shell Completions
# ==============================================================================
# Provides:
#   1. `dev` command: launches on-demand environments in shells/
#   2. Fast, zero-lag auto-completions for `dev` and `box` (Fish, Bash, Zsh)
# ==============================================================================
{
  pkgs,
  flakePath,
  ...
}: let
  inherit (pkgs) lib;

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

      # ── the menu ─────────────────────────────────────────────────────────
      if [ $# -eq 0 ]; then
        echo -e "\033[1;36m╭────────────────────────────────────────────────────────────╮\033[0m"
        echo -e "\033[1;36m│ \033[1;35m🚀 On-Demand DevShell Manager                            \033[1;36m│\033[0m"
        echo -e "\033[1;36m╰────────────────────────────────────────────────────────────╯\033[0m"
        echo -e "\033[1;36m💡 Usage: dev <environment> [command...]   ·   dev -w <env> to inspect\033[0m"
        echo -e "\033[1;33m📦 Environments in $FLAKE_PATH:\033[0m"
        echo
        if META="$(nix eval --json "$FLAKE_PATH#devShellsMeta.$SYSTEM" 2>/dev/null)"; then
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
      if [ "$1" = "-w" ] || [ "$1" = "--what" ]; then
        shift
        [ $# -ge 1 ] || { echo "dev: -w needs an environment name" >&2; exit 1; }
        ENV_NAME="$1"

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

  completions = let
    scan = ''
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
        printf 'ai\t🤖\talias for agent\n'
        printf 'c\t🛠️\talias for build\n'
        printf 'data\t🐍\talias for python\n'
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
          for d in $root/shells/*/
              set -l n (basename $d)
              string match -q '_*' $n; and continue
              set -l icon (sed -n 's/.*icon = "\([^"]*\)".*/\1/p' $d/default.nix 2>/dev/null | head -1)
              set -l desc (sed -n 's/.*description = "\([^"]*\)".*/\1/p' $d/default.nix 2>/dev/null | head -1)
              printf '%s\t%s %s\n' $n "$icon" "$desc"
          end
          printf 'ai\t🤖 alias for agent\n'
          printf 'c\t🛠️ alias for build\n'
          printf 'data\t🐍 alias for python\n'
      end

      complete -c dev -f
      complete -c dev -n __fish_use_subcommand -a '(__dev_shells)'
      complete -c dev -s w -l what -x -a '(__dev_shells)' -d 'list what is inside'
      complete -c dev -n 'not __fish_use_subcommand; and not __fish_seen_argument -s w -l what' \
          -a '(__fish_complete_command)'
    '';

    boxFish = ''
      complete -c box -s e -l ephemeral -l tmp -d 'Pure in-memory RAM mode (tmpfs)'
      complete -c box -s n -l offline -l no-net -d 'Completely cut off network access'
      complete -c box -s P -l proxy -x -d 'Route traffic through local SOCKS5 proxy port (default: 1819)'
      complete -c box -s g -l gpu -d 'Grant access to Nvidia GPU and CUDA devices'
      complete -c box -s s -l share -r -d 'Share host path in Read-Only mode (repeatable, e.g. -s ~/.config/nvim)'
      complete -c box -s S -l share-rw -r -d 'Share host path in Read-Write mode (repeatable, e.g. -S ~/.hermes)'
      complete -c box -s w -l workdir -r -d 'Custom workspace directory (defaults to .box/work/)'
      complete -c box -l mem -x -d 'Cap RAM usage via cgroups (e.g. --mem 4G)'
      complete -c box -l cpu -x -d 'Cap CPU quota via cgroups (e.g. --cpu 200%)'
      complete -c box -l clean -d 'Wipe local .box storage for current project'
      complete -c box -l inspect -d 'Trace file access with strace'
      complete -c box -s h -l help -d 'Show help manual'
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

        if [ "$COMP_CWORD" -gt 1 ] && [ "''${COMP_WORDS[1]}" != "-w" ] && [ "''${COMP_WORDS[1]}" != "--what" ]; then
          mapfile -t COMPREPLY < <(compgen -c -- "$cur")
          return
        fi

        mapfile -t COMPREPLY < <(compgen -W "$(__dev_scan "$root" | cut -f1 | tr '\n' ' ') -w --what" -- "$cur")
      }
      complete -F _dev_complete dev
    '';

    boxBash = ''
      _box_complete() {
        local cur
        cur="''${COMP_WORDS[COMP_CWORD]}"
        local opts="-e --ephemeral --tmp -n --offline --no-net -P --proxy -g --gpu -s --share -S --share-rw -w --workdir --mem --cpu --clean --inspect -h --help"
        mapfile -t COMPREPLY < <(compgen -W "$opts" -- "$cur")
      }
      complete -F _box_complete box
    '';

    zshDev = ''
      #compdef dev
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
        shells+=('ai:alias for agent' 'c:alias for build' 'data:alias for python')
        _describe 'environment' shells
      }
      _dev "$@"
    '';

    zshBox = ''
      #compdef box
      _box() {
        local -a opts
        opts=(
          '-e[Pure in-memory RAM mode (tmpfs)]'
          '--ephemeral[Pure in-memory RAM mode (tmpfs)]'
          '-n[Completely cut off network access]'
          '--offline[Completely cut off network access]'
          '-P[Route traffic through local SOCKS5 proxy]:port:'
          '--proxy[Route traffic through local SOCKS5 proxy]:port:'
          '-g[Grant access to Nvidia GPU and CUDA devices]'
          '--gpu[Grant access to Nvidia GPU and CUDA devices]'
          '-s[Share host path Read-Only]:path:_files'
          '--share[Share host path Read-Only]:path:_files'
          '-S[Share host path Read-Write]:path:_files'
          '--share-rw[Share host path Read-Write]:path:_files'
          '-w[Custom workspace directory]:path:_files -/'
          '--workdir[Custom workspace directory]:path:_files -/'
          '--mem[Cap RAM usage via cgroups]:size:'
          '--cpu[Cap CPU quota via cgroups]:quota:'
          '--clean[Wipe local .box storage for current project]'
          '--inspect[Trace file access with strace]'
          '-h[Show help manual]'
          '--help[Show help manual]'
        )
        _arguments -s $opts '*:command:_command_names -e'
      }
      _box "$@"
    '';
  in
    pkgs.runCommand "dev-and-box-completions" {} ''
      install -Dm444 ${pkgs.writeText "dev.fish" devFish} \
        $out/share/fish/vendor_completions.d/dev.fish
      install -Dm444 ${pkgs.writeText "box.fish" boxFish} \
        $out/share/fish/vendor_completions.d/box.fish

      install -Dm444 ${pkgs.writeText "dev" devBash} \
        $out/share/bash-completion/completions/dev
      install -Dm444 ${pkgs.writeText "box" boxBash} \
        $out/share/bash-completion/completions/box

      install -Dm444 ${pkgs.writeText "_dev" zshDev} \
        $out/share/zsh/site-functions/_dev
      install -Dm444 ${pkgs.writeText "_box" zshBox} \
        $out/share/zsh/site-functions/_box
    '';
in {
  home.packages = [dev completions];
  programs.fish.enable = lib.mkDefault true;
}
