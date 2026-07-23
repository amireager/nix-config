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

  # Remap Zellij Prefix from Ctrl+b to Ctrl+a to match Tmux workflow
  xdg.configFile."zellij/config.kdl".text = ''
    keybinds clear-defaults=true {
      normal {
          bind "Ctrl a" { SwitchToMode "Tmux"; }
      }
      tmux clear-defaults=true {
          bind "Ctrl a" { Write 2; SwitchToMode "Normal"; }
          bind "Esc" { SwitchToMode "Normal"; }
          bind "g" { SwitchToMode "Locked"; }
          bind "p" { SwitchToMode "Pane"; }
          bind "t" { SwitchToMode "Tab"; }
          bind "n" { SwitchToMode "Resize"; }
          bind "h" { SwitchToMode "Move"; }
          bind "s" { SwitchToMode "Scroll"; }
          bind "o" { SwitchToMode "Session"; }
          bind "q" { Quit; }
      }
    }
  '';
}
