{
  inputs,
  proxy,
}: {
  hostname,
  hostModules ? [],
  users ? {},
  system ? "x86_64-linux",
  flakePath ? "/etc/nixos",
  ...
}: let
  inherit (inputs.nixpkgs.lib) mapAttrs mapAttrsToList;
  userSystemModules = mapAttrsToList (_: path: path + "/default.nix") users;
  userHomeModules = mapAttrs (_: path: import (path + "/home.nix")) users;
in
  inputs.nixpkgs.lib.nixosSystem {
    # `system` is deliberately NOT passed here. nixosSystem's own `system`
    # argument is deprecated and triggers:
    #   evaluation warning: 'system' has been renamed to/replaced by
    #   'stdenv.hostPlatform.system'
    # Setting nixpkgs.hostPlatform in a module is the supported way, and it
    # is what the deprecated argument does internally anyway.
    specialArgs = {inherit inputs hostname system flakePath proxy;};
    modules =
      hostModules
      ++ userSystemModules
      ++ [
        {
          nixpkgs.hostPlatform = system;
          networking.hostName = hostname;
        }
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "backup";
            extraSpecialArgs = {inherit inputs hostname system flakePath proxy;};
            users = userHomeModules;

            sharedModules = [
              inputs.nix-index-database.homeModules.nix-index
            ];
          };
        }
      ];
  }
