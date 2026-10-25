{
  config,
  inputs,
  ...
}: let
  # Noctalia 5.0 (the pinned one) defaults to ~/Pictures/Wallpapers and, for its
  # own screenshot service, ~/Pictures, ignoring user-dirs.dirs. 5.3 reads
  # XDG_PICTURES_DIR itself; naming the sub-folders here gives the same layout
  # on both.
  inherit (config.xdg.userDirs) extraConfig;
in {
  imports = [inputs.noctalia.homeModules.default];

  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    settings = {
      shell = {
        font_family = "JetBrainsMono Nerd Font";
        settings_show_advanced = true;
        launch_apps_as_systemd_services = true;
        niri_overview_type_to_launch_enabled = true;

        # Niri enables Polkit itself; Noctalia supplies the graphical agent that
        # presents authentication prompts inside the desktop session.
        polkit_agent = true;

        screenshot.directory = extraConfig.SCREENSHOTS;
      };
      theme = {
        mode = "dark";
        source = "builtin";
        builtin = "Catppuccin";
      };
      wallpaper = {
        enabled = true;
        directory = extraConfig.WALLPAPERS;
      };
      bar.default = {
        position = "top";
        margin_edge = 8;
        margin_ends = 12;
      };
      notification.enable_daemon = true; # singular; 5.3 warns "notifications: unknown section"
      dock = {
        enabled = true;
        position = "bottom";
      };
    };
  };
}
