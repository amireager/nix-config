{...}: {
  imports = [
    ../../modules/home
  ];

  home.username = "amir";
  home.homeDirectory = "/home/amir";
  home.stateVersion = "26.05";
  programs.home-manager.enable = true;
}
