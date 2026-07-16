{...}: {
  imports = [
    ../../modules/home/cli
    ../../modules/home/dev
    ../../modules/home/gui
    ../../modules/home/theme
  ];

  home.username = "amir";
  home.homeDirectory = "/home/amir";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}
