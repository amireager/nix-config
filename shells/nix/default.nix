{
  mkDevShell,
  pkgs,
  ...
}:
# Deliberate split:
#   • statix / deadnix / alejandra / nixd / nix-tree / nix-diff live at SYSTEM
#     level (modules/home/dev/nix-tools.nix). They are used constantly, on
#     .nix files outside this repo, and are what you reach for when something
#     is already broken.
#   • Everything below is packaging/review work: a few times a month, large
#     closures. On-demand is the right trade.
mkDevShell {
  name = "nix";
  icon = "❄️";
  description = "Packaging, review & closure analysis";

  packages = with pkgs; [
    # Writing new packages
    nurl # Generate a fetcher expression from a repo URL
    nix-init # Scaffold a derivation from a URL
    nix-update # Bump version + hashes automatically
    nix-prefetch # Compute hashes for arbitrary fetchers
    nix-prefetch-git # Same, specialised for git sources

    # Reviewing & testing
    nixpkgs-review # Build and report on a nixpkgs PR
    nix-fast-build # Parallel builds across a flake\'s outputs

    # Search & exploration
    nix-search-tv # Interactive fuzzy nixpkgs search (TUI)

    # Diagnostics for the binary caches this system depends on.
    (writeShellApplication {
      name = "nix-cache-doctor";
      runtimeInputs = [
        coreutils
        curl
        gnugrep
        gnused
        nix
      ];
      text = ''
        set -uo pipefail

        C_RESET=$(printf "\033[0m")
        C_BOLD=$(printf "\033[1m")
        C_DIM=$(printf "\033[1;30m")
        C_RED=$(printf "\033[1;31m")
        C_GREEN=$(printf "\033[1;32m")
        C_YELLOW=$(printf "\033[1;33m")
        C_CYAN=$(printf "\033[1;36m")

        # Which cache each pinned input needs. Inputs with `follows = "nixpkgs"`
        # diverge from upstream CI hashes and are built from source locally.
        declare -A INPUT_CACHE=(
          [niri]=""
          [noctalia]=""
          [zen-browser]=""
        )

        # `nix config show <key>` prints the bare value; list settings come
        # back as one space-separated line, so split it here.
        config_values() {
          nix config show "$1" 2>/dev/null | tr ' ' '\n' | sed '/^$/d'
        }

        cache_status() {
          local url="$1" info host priority
          if ! info="$(curl --fail --silent --show-error --location \
            --connect-timeout 10 --max-time 20 \
            --output - "$url/nix-cache-info" 2>/dev/null)"; then
            printf 'down'
            return 1
          fi
          host="$(printf '%s\n' "$url" | sed -e 's|^[a-z][a-z0-9+.-]*://||' -e 's|/.*$||' -e 's|:.*$||')"
          priority="$(printf '%s\n' "$info" | sed -n 's/^Priority: //p' | head -1)"
          if printf '%s\n' "$TRUSTED" | grep -q "^$host-1:" || \
             { [[ "$url" =~ nix-channels/store ]] && printf '%s\n' "$TRUSTED" | grep -q "^cache\.nixos\.org-1:"; }; then
            printf 'ok %s %s' "$host" "''${priority:-?}"
          else
            printf 'untrusted %s %s' "$host" "''${priority:-?}"
          fi
        }

        TRUSTED="$(config_values trusted-public-keys)"
        SUBSTITUTERS="$(config_values substituters)"

        if [ -z "$SUBSTITUTERS" ]; then
          printf '%s✘%s no substituters configured\n' "$C_RED" "$C_RESET" >&2
          exit 1
        fi

        printf '%s━━━ binary caches ━━━%s\n' "$C_CYAN" "$C_RESET"

        declare -A CACHE_STATE=()
        while IFS= read -r raw; do
          [ -n "$raw" ] || continue
          url="''${raw%/}"
          status="$(cache_status "$url")"
          state="''${status%% *}"
          detail="''${status#* }"
          case "$state" in
            ok)
              printf '  %s✔%s %-34s %sreachable%s  %spriority %s · key trusted%s\n' \
                "$C_GREEN" "$C_RESET" "$url" "$C_DIM" "$C_RESET" "$C_DIM" \
                "''${detail##* }" "$C_RESET"
              CACHE_STATE["$url"]="ok"
              ;;
            untrusted)
              printf '  %s▲%s %-34s %sreachable%s  %spriority %s — signing key not trusted%s%s\n' \
                "$C_YELLOW" "$C_RESET" "$url" "$C_DIM" "$C_RESET" "$C_DIM" \
                "''${detail##* }" "$C_YELLOW" "$C_RESET"
              CACHE_STATE["$url"]="untrusted"
              ;;
            *)
              printf '  %s✘%s %-34s %sunreachable%s\n' \
                "$C_RED" "$C_RESET" "$url" "$C_RED" "$C_RESET"
              CACHE_STATE["$url"]="down"
              ;;
          esac
        done <<<"$SUBSTITUTERS"

        printf '\n%s━━━ pinned inputs ━━━%s\n' "$C_CYAN" "$C_RESET"
        while IFS= read -r input; do
          cache="''${INPUT_CACHE[$input]}"
          if [ -z "$cache" ]; then
            printf '  %s▲%s %-14s %sno binary cache — always built from source%s\n' \
              "$C_YELLOW" "$C_RESET" "$input" "$C_DIM" "$C_RESET"
            continue
          fi
          state="''${CACHE_STATE[''${cache%/}]:-not-configured}"
          case "$state" in
            ok)
              printf '  %s✔%s %-14s %s%s%s\n' \
                "$C_GREEN" "$C_RESET" "$input" "$C_DIM" "$cache" "$C_RESET"
              ;;
            not-configured)
              printf '  %s▲%s %-14s %s%s is not in the substituter list%s\n' \
                "$C_YELLOW" "$C_RESET" "$input" "$C_DIM" "$cache" "$C_RESET"
              ;;
            *)
              printf '  %s✘%s %-14s %s%s — unreachable%s\n' \
                "$C_RED" "$C_RESET" "$input" "$C_RED" "$cache" "$C_RESET"
              ;;
          esac
        done < <(printf '%s\n' "''${!INPUT_CACHE[@]}" | sort)

        fallback="$(config_values fallback | head -1)"
        printf '\n%s━━━ policy ━━━%s\n' "$C_CYAN" "$C_RESET"
        printf '  fallback = %s\n' "''${fallback:-unknown}"
        if [ "$fallback" = "false" ]; then
          printf '  %sA cache that returns an error fails the build for the paths it holds%s\n' \
            "$C_DIM" "$C_RESET"
          printf '  %sexclusively, instead of silently starting a source build.%s\n' \
            "$C_DIM" "$C_RESET"
        else
          printf '  %sA broken cache falls back to a source build — possibly a long one.%s\n' \
            "$C_DIM" "$C_RESET"
        fi
        printf '  %sHigher priority is queried first: the Cachix caches (41) are asked before%s\n' \
          "$C_DIM" "$C_RESET"
        printf '  %scache.nixos.org (40), so a broken Cachix cache is the first one to fail.%s\n' \
          "$C_DIM" "$C_RESET"

        printf '\n%s━━━ remedies ━━━%s\n' "$C_CYAN" "$C_RESET"
        printf '  %snix_proxy test%s            check the local proxy listener\n' "$C_BOLD" "$C_RESET"
        printf '  %snix_proxy on%s              route nix-daemon through the proxy\n' "$C_BOLD" "$C_RESET"
        printf '  %snix_proxy off%s             restore the direct daemon\n' "$C_BOLD" "$C_RESET"
        printf '  %snix --option substituters "…"%s  run one command without a cache\n' \
          "$C_BOLD" "$C_RESET"
      '';
    })

    # Fast and deterministic health check. Deliberately no flake evaluation,
    # network access, builds or activation.
    (writeShellApplication {
      name = "nix-check";
      runtimeInputs = [nix statix deadnix alejandra findutils];
      text = ''
        set -u
        status=0
        parsed=0

        echo -e "\033[1;36m[1/4] Nix parser (syntax)...\033[0m"
        while IFS= read -r -d "" file; do
          parsed=$((parsed + 1))
          if ! nix-instantiate --parse "$file" >/dev/null; then
            status=1
          fi
        done < <(find . \
          \( -type d \( -name .git -o -name .direnv -o -name result \) -prune \) -o \
          \( -type f -name "*.nix" -print0\))
        printf "  parsed %d file(s)\n" "$parsed"

        echo -e "\n\033[1;36m[2/4] Statix (anti-patterns)...\033[0m"
        statix check . || status=1

        echo -e "\n\033[1;36m[3/4] Deadnix (unused bindings)...\033[0m"
        deadnix --fail . || status=1

        echo -e "\n\033[1;36m[4/4] Alejandra (format, read-only)...\033[0m"
        alejandra --check . || status=1

        exit "$status"
      '';
    })

    # "Did my change actually make the system bigger?"
    (writeShellScriptBin "nix-size" ''
      set -eu
      TARGET="''${1:-/run/current-system}"
      echo -e "\033[1;36mClosure size of $TARGET:"
      nix path-info -Sh "$TARGET"
      echo
      echo -e "\033[1;36mTop 25 contributors:"
      nix path-info -rSh "$TARGET" | sort -k2 -hr | head -25 \
        | awk '{n=$1; sub(/.*store\/[a-z0-9]*-/,"",n); printf "  %-9s %s\n", $2, n}'
    '')
  ];

  tips = [
    {
      key = "New package";
      cmd = "nix-init / nurl <url>";
    }
    {
      key = "Bump version";
      cmd = "nix-update <attr>";
    }
    {
      key = "Review a PR";
      cmd = "nixpkgs-review pr <number>";
    }
    {
      key = "Health check";
      cmd = "nix-check";
    }
    {
      key = "Cache status";
      cmd = "nix-cache-doctor";
    }
    {
      key = "Closure size";
      cmd = "nix-size [path]";
    }
  ];

  notes = ["statix, deadnix, alejandra, nixd, nix-tree, nix-diff are system-level"];
}
