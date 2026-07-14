{...}: {
  programs.wezterm = {
    enable = true;
    extraConfig = ''
      local wezterm = require 'wezterm'
      local config = wezterm.config_builder()

      config.bidi_enabled = true
      config.harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' }
      config.font = wezterm.font("JetBrainsMono Nerd Font")
      config.font_size = 12.0
      config.window_background_opacity = 0.85
      config.window_padding = {
        left = 10,
        right = 10,
        top = 10,
        bottom = 10,
      }
      config.enable_tab_bar = false
      config.colors = {
        foreground = "#e0e0e0",
        background = "#0b0b0e",
        cursor_bg = "#f5e0dc",
        cursor_fg = "#1e1e2e",
        selection_bg = "#f5e0dc",
        selection_fg = "#1e1e2e",
        ansi = {"#161617","#eb6f92","#a6e3a1","#f9e2af","#89b4fa","#cba6f7","#94e2d5","#cdd6f4"},
        brights = {"#3b3b3b","#f38ba8","#a6e3a1","#f9e2af","#89b4fa","#cba6f7","#94e2d5","#bac2de"},
      }

      return config
    '';
  };

  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 12;
    };
    settings = {
      background_opacity = "0.85";
      dynamic_background_opacity = "yes";
      background = "#0b0b0e";
      foreground = "#e0e0e0";
      window_padding_width = 10;
      confirm_os_window_close = 0;
      cursor_shape = "beam";
      repaint_delay = 10;
      input_delay = 3;
      scrollback_lines = 10000;
      enable_audio_bell = false;
      visual_bell_duration = 0;
      disable_ligatures = "never";
      color0 = "#161617";
      color1 = "#eb6f92";
      color2 = "#a6e3a1";
      color3 = "#f9e2af";
      color4 = "#89b4fa";
      color5 = "#cba6f7";
      color6 = "#94e2d5";
      color7 = "#cdd6f4";
      color8 = "#3b3b3b";
      color9 = "#f38ba8";
      color10 = "#a6e3a1";
      color11 = "#f9e2af";
      color12 = "#89b4fa";
      color13 = "#cba6f7";
      color14 = "#94e2d5";
      color15 = "#bac2de";
      cursor = "#f5e0dc";
      cursor_text_color = "#1e1e2e";
      selection_foreground = "#1e1e2e";
      selection_background = "#f5e0dc";
    };
    keybindings = {
      "ctrl+shift+c" = "copy_to_clipboard";
      "ctrl+shift+v" = "paste_from_clipboard";
      "ctrl+shift+up" = "scroll_line_up";
      "ctrl+shift+down" = "scroll_line_down";
      "ctrl+shift+page_up" = "scroll_page_up";
      "ctrl+shift+page_down" = "scroll_page_down";
      "ctrl+shift+home" = "scroll_home";
      "ctrl+shift+end" = "scroll_end";
      "ctrl+shift+f" = "show_scrollback";
    };
  };
}
