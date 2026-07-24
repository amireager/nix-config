{...}: {
  programs.zellij = {
    enable = true;
    enableFishIntegration = false; # We'll launch it manually or via alias
  };

  # ============================================================
  # ZELLIJ NATIVE CONFIGURATION (Embracing its true power)
  # ============================================================
  xdg.configFile."zellij/config.kdl".text = ''
    theme "catppuccin-mocha"
    // We use 'default' layout instead of 'compact' to keep the bottom hint bar visible
    default_layout "default"
    pane_frames false

    ui {
        pane_frames {
            rounded_corners true
        }
    }

    themes {
        catppuccin-mocha {
            bg "#585b70"
            fg "#cdd6f4"
            red "#f38ba8"
            green "#a6e3a1"
            blue "#89b4fa"
            yellow "#f9e2af"
            magenta "#f5c2e7"
            orange "#fab387"
            cyan "#94e2d5"
            black "#181825"
            white "#ffffff"
        }
    }
  '';

  # === Zellij Dev Layout ===
  # You can run: `zellij --layout dev` to instantly spawn this workspace
  xdg.configFile."zellij/layouts/dev.kdl".text = ''
    layout {
        pane split_direction="vertical" {
            pane size="65%" focus=true command="nvim"
            pane split_direction="horizontal" {
                pane size="35%" command="btop"
                pane size="65%"
            }
        }
        pane size=1 borderless=true {
            plugin location="zellij:status-bar"
        }
    }
  '';
}
