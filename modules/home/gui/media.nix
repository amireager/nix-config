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

    # ── Archive & File Management ──
    zip
    unzip
    p7zip
    unrar

    # ── Notifications ──
    libnotify

    # ── Media Processing ──
    # ffmpeg stays: mpv, ffmpegthumbnailer and the file manager preview
    # pipeline all link against it. Removing it frees nothing and breaks
    # thumbnails. The heavyweight `ffmpeg-full` lives in `dev media`.
    ffmpeg
    ffmpegthumbnailer

    # ── Image / PDF tools ──
    poppler-utils # pdftotext/pdfinfo — used by previewers and scripts

    marker
    guvcview
    # Moved to `dev media` (rarely used, heavy GTK/Qt closures):
    #   imagemagick, vips, pinta, pdfarranger
    # yt-dlp is declared once in cli/tools.nix instead of twice.
  ];
}
