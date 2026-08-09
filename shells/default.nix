# ==============================================================================
# DEVSHELLS REGISTRY — Central Hub for Modular On-Demand Environments
# ==============================================================================
# Every subdirectory here is a self-contained environment, realised only when
# it is actually entered (`dev <name>` / `nix develop .#<name>`).
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
    "agent"
    "audit"
    "box"
    "build"
    "cli"
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
      title = "AI & Autonomous Agents";
      members = ["agent"];
    }
    {
      title = "Languages, Data & Runtimes";
      members = ["python" "rust" "go" "web"];
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
      title = "Security & Isolation";
      members = ["box" "audit"];
    }
  ];

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
      ai = "agent";
      c = "build";
      default = "nix";
      data = "python";
    };
  };
in
  shells
  // {
    # `nix develop` with no argument, and `dev` with no argument.
    default = shells.nix;

    # Aliases
    ai = shells.agent;
    c = shells.build;
    data = shells.python;

    # Not a shell: metadata for the `dev` launcher's menu.
    devShellsMeta = meta;
  }
