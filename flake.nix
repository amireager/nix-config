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
  };

  outputs = inputs @ {self, ...}: let
    system = "x86_64-linux";
    pkgs = inputs.nixpkgs.legacyPackages.${system};
    lib = import ./lib {inherit inputs;};
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
    devShells.${system} = import ./shells {
      inherit inputs pkgs system;
    };

    formatter.${system} = pkgs.alejandra;
  };
}
