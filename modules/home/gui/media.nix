{pkgs, ...}: {
  home.packages = with pkgs; [
    # Image viewer
    imv # minimal image viewer (Wayland-native)

    # Video & audio player
    mpv # media player (all formats)
    playerctl # media key control (play/pause/next)

    # PDF viewer
    zathura # vim-like PDF viewer

    # MarkDown viewer
    inlyne # markdown renderer in gui

    # Note taking
    joplin # lightweight markdown notes with sync

    # Camera
    cheese # webcam app — photos, videos, effects

    # Archive tools
    zip # create zip archives
    unzip # extract zip archives
    p7zip # 7z support
    unrar # rar extraction

    # Mount & notifications
    udiskie # auto-mount USB drives
    libnotify # desktop notifications (notify-send)

    # Media processing — essential
    ffmpeg # all-in-one media converter/editor
    yt-dlp # download from YouTube and 1000+ sites
    imagemagick # image convert, resize, annotate
  ];
}
