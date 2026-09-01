{
  description = "Amir's NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:YaLTeR/niri";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia/cachix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Pre-built nix-index database, rebuilt daily upstream.
    # Replaces local `nix-index` runs (~10 min of CPU) and makes `comma`
    # work immediately after a fresh install.
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: let
    # The architecture of the *development shell / formatter* outputs — this is
    # the platform the config is developed on. Each NixOS host sets its OWN
    # system (see the `system` argument passed to lib.mkHost below), so a host
    # can be a different architecture later without touching this line.
    devSystem = "x86_64-linux";

    # DevShells include CUDA-enabled AI tooling, so their standalone package set
    # needs the same unfree policy as the NixOS configuration.
    pkgs = import inputs.nixpkgs {
      system = devSystem;
      config.allowUnfree = true;
    };

    lib = import ./lib {inherit inputs;};
    shells = import ./shells {
      inherit inputs pkgs;
      system = devSystem;
    };
  in {
    nixosConfigurations = {
      laptop = lib.mkHost {
        hostname = "laptop";
        # Explicit, per-host architecture (overridable here if the host differs).
        system = devSystem;
        hostModules = [./hosts/laptop];
        users.amir = ./users/amir;
      };
    };

    # Centralized On-Demand Environments (GC-Resilient & Modular).
    # Each derivation keeps its own metadata in passthru.devShellMeta; the Flake
    # exposes only standard devShell outputs.
    devShells.${devSystem} = shells;

    formatter.${devSystem} = pkgs.alejandra;
  };
}
