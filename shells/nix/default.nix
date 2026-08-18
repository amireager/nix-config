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
          \( -type f -name "*.nix" -print0 \))
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
      key = "Closure size";
      cmd = "nix-size [path]";
    }
  ];

  notes = ["statix, deadnix, alejandra, nixd, nix-tree, nix-diff are system-level"];
}
