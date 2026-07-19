{pkgs, ...}: {
  # Automount external USB drives & notify
  services.udiskie = {
    enable = true;
    automount = true;
    notify = true;
    tray = "auto";
  };

  # Hardware-accelerated video playback with MPV
  programs.mpv = {
    enable = true;
    config = {
      hwdec = "auto-safe";
      vo = "gpu-next";
      gpu-api = "vulkan";
      profile = "gpu-hq";
    };
  };

  home.packages = with pkgs; [
    # ── Image Viewing & Management ──
    imv
    loupe

    # ── Video & Audio ──
    playerctl
    celluloid

    # ── Document & Reading ──
    zathura
    inlyne
    marker

    # ── Capture & Input ──
    guvcview
    kooha

    # ── Archive & File Management ──
    zip
    unzip
    p7zip
    unrar

    # ── Notifications ──
    libnotify

    # ── Media Processing ──
    ffmpeg
    ffmpegthumbnailer
    yt-dlp
    imagemagick

    # ── Image / PDF tools ──
    pinta
    poppler-utils
    pdfarranger
  ];
}
