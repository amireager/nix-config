# Fish, Bash, and Zsh completion definitions for the unchanged dev CLI.
{
  pkgs,
  flakePath,
  registry,
}: let
  inherit (pkgs) lib;

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
    complete -c dev -l roots -d 'List local root state and closure sizes'
    complete -c dev -l unkeep -x -a '(__dev_roots)' -d 'Remove one GC root'
    complete -c dev -l unkeep-all -d 'Remove every devShell GC root'
    complete -c dev -l prune -d 'Remove directory-only, broken, legacy and orphan roots'
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
      '--roots[list local root state and closure sizes]' \
      '--unkeep[remove one GC root]:root:->roots' \
      '--unkeep-all[remove every GC root]' \
      '--prune[remove directory-only, broken, legacy and orphan roots]' \
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
  ''
