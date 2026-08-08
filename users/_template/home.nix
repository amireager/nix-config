{...}: {
  imports = [
    # Add your imported modules from ../../modules/home/...
  ];

  home = {
    username = "username";
    homeDirectory = "/home/username";
    stateVersion = "26.05";
  };

  programs.home-manager.enable = true;
}
