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

    # Thorium removed — flake repos unreliable (504 timeout)
    # Use AppImage instead: download from https://github.com/Alex313031/Thorium/releases
    # programs.appimage is already enabled in core.nix
  };

  outputs = inputs @ {self, ...}: let
    lib = import ./lib {inherit inputs;};
  in {
    nixosConfigurations = {
      nixos = lib.mkHost {
        hostname = "nixos";
        hostModules = [./hosts/nixos];
        userModules.amir = [./users/amir];
      };
    };

    formatter.x86_64-linux = inputs.nixpkgs.legacyPackages.x86_64-linux.alejandra;
  };
}
