{inputs}: {
  hostname,
  hostModules ? [],
  userModules ? {},
  system ? "x86_64-linux",
  flakePath ? "/etc/nixos",
  ...
}: let
  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };

  specialArgs = {inherit inputs hostname flakePath system;};

  hmUserConfigs =
    builtins.mapAttrs
    (_: modules: {imports = modules;})
    userModules;
in
  inputs.nixpkgs.lib.nixosSystem {
    inherit system specialArgs;
    modules =
      hostModules
      ++ (
        if userModules != {}
        then [
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
              extraSpecialArgs = specialArgs;
              users = hmUserConfigs;
            };
          }
        ]
        else []
      );
  }
