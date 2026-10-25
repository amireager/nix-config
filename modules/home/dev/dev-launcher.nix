# ==============================================================================
# dev — module wiring for runtime, root management, and completions
# ==============================================================================
{
  config,
  pkgs,
  flakePath,
  ...
}: let
  inherit (pkgs) lib;

  # Where `dev` looks for the flake when neither $NIX_CONFIG_FLAKE nor flakePath
  # has one (recovery, or a checkout that is not symlinked to /etc/nixos). The
  # projects folder comes from xdg.userDirs (modules/home/gui/xdg.nix), so it
  # follows that layout instead of a hard-coded ~/projects.
  flakeFallbacks = [
    "$HOME/nix-config"
    "${lib.replaceStrings [config.home.homeDirectory] ["$HOME"] config.xdg.userDirs.projects}/nix-config"
    "/etc/nixos"
  ];

  registry = import ../../../shells/registry.nix;
  roots = import ./dev-launcher/roots.nix {inherit pkgs;};
  dev = import ./dev-launcher/runtime.nix {
    inherit pkgs flakePath flakeFallbacks registry roots;
  };
  completions = import ./dev-launcher/completions.nix {
    inherit pkgs flakePath flakeFallbacks registry;
  };
in {
  home.packages = [dev completions];
  programs.fish.enable = lib.mkDefault true;
}
