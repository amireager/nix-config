# ==============================================================================
# dev — module wiring for runtime, root management, and completions
# ==============================================================================
{
  pkgs,
  flakePath,
  ...
}: let
  inherit (pkgs) lib;

  registry = import ../../../shells/registry.nix;
  roots = import ./dev-launcher/roots.nix {inherit pkgs;};
  dev = import ./dev-launcher/runtime.nix {
    inherit pkgs flakePath registry roots;
  };
  completions = import ./dev-launcher/completions.nix {
    inherit pkgs flakePath registry;
  };
in {
  home.packages = [dev completions];
  programs.fish.enable = lib.mkDefault true;
}
