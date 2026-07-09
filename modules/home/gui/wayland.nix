{pkgs, ...}: {
  home.packages = with pkgs; [
    # Screenshot tools
    grim         # screenshot tool (Wayland)
    slurp        # region selection for grim
    wl-screenrec # screen recorder (Wayland)

    # Hardware controls
    brightnessctl # screen brightness control
    pamixer      # PulseAudio volume control (CLI)
    bluetui      # Bluetooth TUI manager

    # Clipboard
    wl-clipboard # Wayland clipboard (wl-copy/wl-paste)
  ];
}
