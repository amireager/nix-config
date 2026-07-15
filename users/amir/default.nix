{lib, ...}: {
  imports = [
    ../../modules/home
  ];

  home.username = "amir";
  home.homeDirectory = lib.mkDefault "/home/amir";
  home.stateVersion = "26.05";
  programs.home-manager.enable = true;
}
