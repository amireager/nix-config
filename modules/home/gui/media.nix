{pkgs, ...}: {
  home.packages = with pkgs; [
    # ── Image Viewing & Management ──
    imv
    loupe
    nomacs

    # ── Video & Audio ──
    mpv
    playerctl
    celluloid

    # ── Document & Reading ──
    zathura
    inlyne
    marker

    # ── Capture & Input ──
    guvcview
    wf-recorder
    kooha

    # ── Archive & File Management ──
    zip
    unzip
    p7zip
    unrar

    # ── Auto-mount & Notifications ──
    udiskie
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
