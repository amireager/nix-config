{
  pkgs,
  inputs,
  config,
  ...
}: {
  home.packages = [
    inputs.zen-browser.packages."${pkgs.stdenv.hostPlatform.system}".default
    pkgs.telegram-desktop
    pkgs.qutebrowser
  ];

  programs.firefox = {
    enable = true;
    configPath = "${config.xdg.configHome}/mozilla/firefox";
  };
}
