{
  config,
  lib,
  pkgs,
  ...
}: let
  # strftime(3) pattern; niri creates the last folder, xdg.nix creates its parent.
  screenshotPath = "${config.xdg.userDirs.extraConfig.SCREENSHOTS}/Screenshot from %Y-%m-%d %H-%M-%S.png";
in {
  home.packages = with pkgs; [
    networkmanagerapplet
    swayidle
    swaylock # lock screen fallback
    xwayland-satellite
  ];

  xdg.configFile."niri/config.kdl".text =
    lib.replaceStrings ["@screenshotPath@"] [screenshotPath] (builtins.readFile ./config.kdl);

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    XDG_CURRENT_DESKTOP = "niri";
    XDG_SESSION_TYPE = "wayland";
    QT_QPA_PLATFORM = "wayland;xcb";
    # DISPLAY is auto-set by XWayland — do NOT set manually for Wayland sessions
  };
}
