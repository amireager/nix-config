# Copy this directory to users/<username>/ and customize.
{...}: {
  imports = [
    ../../modules/home/cli
    # ../../modules/home/dev
    # ../../modules/home/gui
    # ../../modules/home/theme
  ];

  home.username = "username";
  home.homeDirectory = "/home/username";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}
