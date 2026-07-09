{pkgs, ...}: {
  home.packages = with pkgs; [
    fd bat ripgrep jq
    eza yazi glow
    grc
  ];

  programs.bat = {
    enable = true;
    config = {
      theme = "ansi";
      style = "numbers,changes,header";
    };
  };

  programs.tealdeer = {
    enable = true;
    settings.updates.auto_update = true;
  };

  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    shellWrapperName = "y";
  };

  programs.btop.enable = true;
  programs.fastfetch.enable = true;
  programs.lazygit.enable = true;
  programs.broot.enable = true;
}
