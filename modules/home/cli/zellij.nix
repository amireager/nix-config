{...}: {
  programs.zellij = {
    enable = true;
    enableFishIntegration = false; # We'll launch it manually or via alias
    settings = {
      theme = "catppuccin-mocha";
      themes.catppuccin-mocha = {
        bg = "#585b70";
        fg = "#cdd6f4";
        red = "#f38ba8";
        green = "#a6e3a1";
        blue = "#89b4fa";
        yellow = "#f9e2af";
        magenta = "#f5c2e7";
        orange = "#fab387";
        cyan = "#94e2d5";
        black = "#181825";
        white = "#ffffff";
      };
      default_layout = "compact";
      pane_frames = false;
      ui.pane_frames.rounded_corners = true;
    };
  };
}
