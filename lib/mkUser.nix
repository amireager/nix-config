# Builder for creating reusable user configurations
# Usage: mkUser { name = "amir"; modules = [...]; }
{inputs, lib ? inputs.nixpkgs.lib}:
{
  name,
  modules ? [],
  homeDirectory ? "/home/${name}",
  stateVersion ? "26.05",
  description ? "User ${name}",
  extraConfig ? {},
  ...
} @ config:

let
  helpers = import ./helpers.nix {inherit lib;};
in

# Validate
(helpers.validateKeys ["name"] config)

# Return user configuration
{
  home.username = name;
  home.homeDirectory = homeDirectory;
  home.stateVersion = stateVersion;
  home.description = description;
  programs.home-manager.enable = true;

  # Import user-specific modules
  imports = modules;

  # Merge any extra config
} // extraConfig
