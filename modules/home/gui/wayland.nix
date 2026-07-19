{pkgs, ...}: {
  # Clipboard daemon & history manager
  services.cliphist.enable = true;

  # Ultra-fast Wayland application & menu launcher (Catppuccin Mocha)
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        font = "JetBrainsMono Nerd Font:size=11";
        terminal = "kitty";
        icon-theme = "Papirus-Dark";
        layer = "overlay";
        width = 60;
        horizontal-pad = 20;
        vertical-pad = 15;
        inner-pad = 10;
        line-height = 20;
      };
      colors = {
        background = "1e1e2edd";
        text = "cdd6f4ff";
        match = "f38ba8ff";
        selection = "313244ff";
        selection-text = "cdd6f4ff";
        selection-match = "f38ba8ff";
        border = "89b4faff";
      };
      border = {
        width = 2;
        radius = 12;
      };
    };
  };

  home.packages = with pkgs; [
    # Screenshot tools
    grim         # screenshot tool (Wayland)
    slurp        # region selection for grim
    wl-screenrec # screen recorder (Wayland)

    # Hardware controls
    brightnessctl # screen brightness control
    pamixer      # PulseAudio volume control (CLI)
    bluetui      # Bluetooth TUI manager

    # Clipboard & Wayland tools
    wl-clipboard # Wayland clipboard (wl-copy/wl-paste)
    cliphist     # Clipboard history CLI
  ];
}
