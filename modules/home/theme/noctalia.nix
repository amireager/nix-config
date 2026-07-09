{inputs, ...}: {
  imports = [inputs.noctalia.homeModules.default];

  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    settings = {
      shell = {
        font = "JetBrainsMono Nerd Font";
        settings_show_advanced = true;
        launch_apps_as_systemd_services = true;
      };
      theme = {
        mode = "dark";
        source = "builtin";
        builtin = "Catppuccin";
      };
      wallpaper.enabled = true;
      bar = {
        position = "top";
        margin_top = 8;
        margin_left = 12;
        margin_right = 12;
      };
      notifications = {
        enabled = true;
        timeout = 5000;
      };
      launcher.enable = true;
      control_center.enable = true;
      dock = {
        enabled = true;
        position = "bottom";
      };
      niri.overview_type_to_launch_enabled = true;
    };
  };
}
