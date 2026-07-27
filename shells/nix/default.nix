{mkDevShell, pkgs, ...}:
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

    # Unified health check. Uses the system-level linters so the shell stays small.
    (writeShellScriptBin "nix-check" ''
      set -u
      echo -e "\033[1;36m[1/3] 🔍 Statix (anti-patterns)..."
      ${statix}/bin/statix check . || true

      echo -e "\n\033[1;33m[2/3] 💀 Deadnix (unused bindings)..."
      ${deadnix}/bin/deadnix . || true

      echo -e "\n\033[1;35m[3/3] ❄️  Flake evaluation..."
      nix flake check --no-build "$@"
    '')

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
    {key = "New package"; cmd = "nix-init / nurl <url>";}
    {key = "Bump version"; cmd = "nix-update <attr>";}
    {key = "Review a PR"; cmd = "nixpkgs-review pr <number>";}
    {key = "Health check"; cmd = "nix-check";}
    {key = "Closure size"; cmd = "nix-size [path]";}
  ];

  notes = ["statix, deadnix, alejandra, nixd, nix-tree, nix-diff are system-level"];
}
