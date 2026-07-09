{pkgs, ...}: {
  home.packages = with pkgs; [
    nixd
    nix-tree
    nvd
    nix-search-tv
    comma
    nix-index
  ];
}
