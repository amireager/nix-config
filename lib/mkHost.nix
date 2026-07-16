{inputs}: {
  hostname,
  hostModules ? [],
  users ? {},
  system ? "x86_64-linux",
  flakePath ? "/etc/nixos",
  ...
}: let
  inherit (inputs.nixpkgs.lib) mapAttrs mapAttrsToList;
  userSystemModules = mapAttrsToList (name: path: path + "/default.nix") users;
  userHomeModules = mapAttrs (name: path: import (path + "/home.nix")) users;
in
  inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = {inherit inputs hostname system flakePath;};
    modules =
      hostModules
      ++ userSystemModules
      ++ [
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "backup";
            extraSpecialArgs = {inherit inputs hostname system flakePath;};
            users = userHomeModules;
          };
        }
      ];
  }
