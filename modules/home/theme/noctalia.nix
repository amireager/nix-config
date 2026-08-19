{inputs, ...}: {
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
      };
      theme = {
        mode = "dark";
        source = "builtin";
        builtin = "Catppuccin";
      };
      wallpaper.enabled = true;
      bar.default = {
        position = "top";
        margin_edge = 8;
        margin_ends = 12;
      };
      notifications.enable_daemon = true;
      dock = {
        enabled = true;
        position = "bottom";
      };
    };
  };
}
