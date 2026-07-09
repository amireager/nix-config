{pkgs, ...}: {
  home.packages = with pkgs; [
    nixd             # Nix LSP for editor integration
    nix-tree         # explore Nix store dependency tree
    nvd              # diff between NixOS generations
    nix-search-tv    # interactive nixpkgs search (TUI)
    comma            # run any command without installing
    nix-index        # locate packages providing a file
    nix-output-monitor # beautiful build output with progress
  ];
}
