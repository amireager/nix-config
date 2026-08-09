{...}: {
  imports = [
    # Add your imported modules from ../../modules/home/...
    ../../modules/home/cli/fish.nix
    ../../modules/home/cli/starship.nix
    ../../modules/home/cli/direnv.nix
    ../../modules/home/cli/tools.nix
  ];

  home = {
    username = "username";
    homeDirectory = "/home/username";
    stateVersion = "26.05";
  };

  programs.home-manager.enable = true;
}
