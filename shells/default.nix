# ==============================================================================
# DEVSHELLS REGISTRY — Central Hub for Modular On-Demand Environments
# ==============================================================================
# Every subdirectory here is a self-contained environment, realised only when
# it is actually entered (`dev <name>` / `nix develop .#<name>`).
#
# Adding a shell:
#   1. cp -r shells/_template shells/<name>
#   2. add one line to `shellDirs` below
# ==============================================================================
{
  inputs,
  pkgs,
  system ? "x86_64-linux",
  ...
}: let
  inherit (pkgs) lib;

  # The builder from lib/, already applied to this pkgs.
  mkDevShell = (import ../lib {inherit inputs;}).mkDevShellFor pkgs;

  # Arguments handed to every shell module. A shell may ignore any of them.
  shellArgs = {inherit mkDevShell pkgs inputs system lib;};

  # Registered environments. `_template` is deliberately excluded.
  shellDirs = [
    "ai"
    "box"
    "build"
    "cli"
    "data"
    "go"
    "media"
    "nix"
    "python"
    "rust"
    "sec"
    "web"
  ];

  # Import a shell directory. Supports both shapes:
  #   • mkDevShell { ... }              -> a derivation
  #   • { default = pkgs.mkShell {...}; } -> the legacy/escape-hatch shape
  importShell = name: let
    result = import (./. + "/${name}") shellArgs;
  in
    if lib.isDerivation result
    then result
    else result.default;

  shells = lib.genAttrs shellDirs importShell;
in
  shells
  // {
    # `nix develop` with no argument, and `dev` with no argument.
    default = shells.nix;

    # Alias: `dev c` -> `dev build`
    c = shells.build;

    # Composite environment for cross-language work.
    test = mkDevShell {
      name = "test";
      icon = "🧪";
      description = "Composite: Python + Rust toolchains";
      inputsFrom = [shells.python shells.rust];
      tips = [
        {
          key = "Python";
          cmd = "pytest / ruff check .";
        }
        {
          key = "Rust";
          cmd = "cargo test";
        }
      ];
    };
  }
