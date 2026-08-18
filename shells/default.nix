# ==============================================================================
# DEVSHELLS REGISTRY — Central Hub for Modular On-Demand Environments
# ==============================================================================
# Every registered module here is a self-contained environment, realised only
# when it is actually entered (`dev <name>` / `nix develop .#<name>`).
# Names, groups and aliases are pure data in ./registry.nix and are also read by
# the global `dev` launcher, keeping menus and completions in sync.
# ==============================================================================
{
  inputs,
  pkgs,
  system ? "x86_64-linux",
  ...
}: let
  inherit (pkgs) lib;

  registry = import ./registry.nix;

  # The builder from lib/, already applied to this pkgs.
  mkDevShell = (import ../lib {inherit inputs;}).mkDevShellFor pkgs;

  # Arguments handed to every shell module. A shell may ignore any of them.
  shellArgs = {inherit mkDevShell pkgs inputs system lib;};

  # Import a directory- or file-based shell module. Supports both result shapes:
  #   • mkDevShell { ... }                -> a derivation
  #   • { default = pkgs.mkShell { ... }; } -> the legacy/escape-hatch shape
  importShell = name: let
    directoryModule = ./. + "/${name}/default.nix";
    fileModule = ./. + "/${name}.nix";
    modulePath =
      if builtins.pathExists directoryModule
      then directoryModule
      else fileModule;
    result = import modulePath shellArgs;
  in
    if lib.isDerivation result
    then result
    else result.default;

  shells = lib.genAttrs registry.shellDirs importShell;

  aliasShells = lib.mapAttrs (_alias: target: shells.${target}) registry.aliases;

  meta = {
    shells =
      lib.mapAttrs
      (name: drv:
        drv.passthru.devShellMeta or {
          inherit name;
          icon = "📦";
          description = "";
        })
      shells;
    inherit (registry) groups aliases;
  };
in
  shells
  // aliasShells
  // {
    # Not a shell: metadata for the `dev` launcher's menu.
    devShellsMeta = meta;
  }
