# ==============================================================================
# DEVSHELL OUTPUTS — import registered on-demand environments
# ==============================================================================
{
  inputs,
  pkgs,
  system ? "x86_64-linux",
  ...
}: let
  inherit (pkgs) lib;

  registry = import ./registry.nix;
  mkDevShell = (import ../lib {inherit inputs;}).mkDevShellFor pkgs;
  shellArgs = {inherit mkDevShell pkgs inputs system lib;};

  directoryModule = name: ./. + "/${name}/default.nix";
  fileModule = name: ./. + "/${name}.nix";
  hasModule = name:
    builtins.pathExists (directoryModule name)
    || builtins.pathExists (fileModule name);
  missingModules = builtins.filter (name: !(hasModule name)) registry.shellDirs;

  # Supports both the normal mkDevShell derivation and the legacy escape-hatch
  # shape `{ default = pkgs.mkShell { ... }; }`.
  importShell = name: let
    modulePath =
      if builtins.pathExists (directoryModule name)
      then directoryModule name
      else fileModule name;
    result = import modulePath shellArgs;
  in
    if lib.isDerivation result
    then result
    else result.default;

  shells = lib.genAttrs registry.shellDirs importShell;
  aliasShells = lib.mapAttrs (_alias: target: shells.${target}) registry.aliases;
in
  assert missingModules == [] || throw "devShell registry: missing modules: ${lib.concatStringsSep ", " missingModules}";
    shells // aliasShells
