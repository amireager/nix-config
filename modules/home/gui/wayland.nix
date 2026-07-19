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
    # Screenshot, Recording & Keycasting Tools
    grim                  # Wayland screenshot tool
    slurp                 # Interactive region selection for grim
    wl-screenrec          # Hardware-accelerated Wayland screen recorder (Vulkan/VA-API)
    gpu-screen-recorder     # Ultra-fast GPU screen recorder
    gpu-screen-recorder-gtk # Initial GUI menu for recording (region/window/audio toggle)
    wshowkeys             # Live Wayland keycaster (shows pressed keys on screen during recording)

    # Hardware & Audio Controls
    brightnessctl # Screen brightness control
    pamixer      # PulseAudio volume control CLI
    bluetui      # Bluetooth TUI manager

    # Clipboard & Wayland Utilities
    wl-clipboard # Wayland clipboard utilities (wl-copy / wl-paste)
    cliphist     # Clipboard history CLI (To wipe all: `cliphist wipe && wl-copy --clear`)

    # Keyboard-Centric Fuzzel Utilities
    networkmanager_dmenu # NetworkManager dmenu/fuzzel WiFi switcher
    libqalculate         # Powerful command-line calculation engine (qalc)

    # --- Helper Script: Instant Fuzzel Calculator ---
    (writeShellScriptBin "fuzzel-calc" ''
      RESULT=$(fuzzel --dmenu --prompt "🧮 Calc > " --width 40 --lines 0 | xargs -I {} qalc -t "{}")
      if [ -n "$RESULT" ]; then
        echo -n "$RESULT" | wl-copy
        notify-send -t 3000 "🧮 Calculator" "Result copied to clipboard:\n<b>$RESULT</b>"
      fi
    '')

    # --- Helper Script: Fuzzel WiFi Switcher ---
    (writeShellScriptBin "fuzzel-wifi" ''
      exec networkmanager_dmenu -l 20
    '')

    # --- Helper Script: Open Recording GUI Menu or Toggle Recording ---
    (writeShellScriptBin "record-screen" ''
      if pgrep -x wl-screenrec > /dev/null; then
        pkill -INT -x wl-screenrec
        notify-send -t 4000 "🎥 Screen Recorder" "Recording stopped and saved to $HOME/Videos."
      elif pgrep -x gpu-screen-rec > /dev/null; then
        pkill -INT -x gpu-screen-rec
        notify-send -t 4000 "🎥 Screen Recorder" "Recording stopped."
      else
        # Launch the intuitive GUI menu to select window/region, toggle audio and start
        gpu-screen-recorder-gtk &
      fi
    '')

    # --- Helper Script: Toggle Live Keycaster (Show keys on screen) ---
    (writeShellScriptBin "toggle-keycaster" ''
      if pgrep -x wshowkeys > /dev/null; then
        pkill -x wshowkeys
        notify-send -t 2000 "⌨️ Keycaster" "Keycaster stopped."
      else
        notify-send -t 2500 "⌨️ Keycaster" "Showing pressed keys on screen."
        wshowkeys -a -b "#1e1e2ecc" -f "#cdd6f4ff" &
      fi
    '')

    # --- Helper Script: Instant Region Screenshot to Clipboard ---
    (writeShellScriptBin "capture-region-clipboard" ''
      slurp | grim -g - - | wl-copy
      notify-send -t 2500 "📸 Screenshot" "Captured selected region directly to clipboard."
    '')
  ];
}
