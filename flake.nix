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

    agenix = {
      url = "github:ryantm/agenix";
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
    system = "x86_64-linux";
    # DevShells include CUDA-enabled AI tooling, so their standalone package set
    # needs the same unfree policy as the NixOS configuration.
    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    lib = import ./lib {inherit inputs;};
    shells = import ./shells {
      inherit inputs pkgs system;
    };
  in {
    nixosConfigurations = {
      nixos = lib.mkHost {
        hostname = "nixos";
        hostModules = [./hosts/nixos];
        users.amir = ./users/amir;
      };
    };

    # Centralized On-Demand Environments (GC-Resilient & Modular)
    # Quick invocation from anywhere using `nix develop .#<name>` or `dev <name>`
    devShells.${system} = builtins.removeAttrs shells ["devShellsMeta"];

    # Expose devShells metadata separately to maintain a valid Nix Flake schema
    devShellsMeta.${system} = shells.devShellsMeta;

    formatter.${system} = pkgs.alejandra;
  };
}
