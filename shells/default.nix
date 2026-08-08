# ==============================================================================
# DEVSHELLS REGISTRY — Central Hub for Modular On-Demand Environments
# ==============================================================================
# Every subdirectory here is a self-contained environment, realised only when
# it is actually entered (`dev <name>` / `nix develop .#<name>`).
#
# Adding a shell:
#   1. cp -r shells/_template shells/<name>
#   2. add one line to `shellDirs` below
#
# The `dev` launcher builds its menu from `devShellMeta`, exported below, so
# a new shell shows up there automatically — no second list to update.
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
    "audit"
    "box"
    "build"
    "cli"
    "data"
    "go"
    "media"
    "nix"
    "python"
    "rust"
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

  # Grouping is presentation only: it decides the headings the `dev` menu
  # prints. A shell missing from every group still appears, under "Other".
  groups = [
    {
      title = "Languages & Runtimes";
      members = ["python" "rust" "go" "web"];
    }
    {
      title = "Data";
      members = ["data"];
    }
    {
      title = "Media & Content";
      members = ["media"];
    }
    {
      title = "System, Build & QA";
      members = ["cli" "build" "nix"];
    }
    {
      title = "Security";
      members = ["box" "audit"];
    }
  ];

  # Machine-readable description of every shell, consumed by the `dev`
  # launcher. Aliases are listed separately so the menu can mention them
  # without implying they are separate environments.
  meta = {
    shells =
      lib.mapAttrs
      (n: drv:
        drv.passthru.devShellMeta or {
          name = n;
          icon = "📦";
          description = "";
        })
      shells;
    inherit groups;
    aliases = {
      c = "build";
      default = "nix";
    };
    extra = {
      test = {
        icon = "🧪";
        description = "Composite: Python + Rust toolchains";
      };
    };
  };
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

    # Not a shell: metadata for the `dev` launcher's menu.
    # Hidden from `nix flake show` output by convention (leading underscore
    # would break genAttrs consumers, so it is documented instead).
    devShellsMeta = meta;
  }
