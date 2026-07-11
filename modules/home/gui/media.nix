{pkgs, ...}: {
  home.packages = with pkgs; [
    # Image viewer
    imv # minimal image viewer (Wayland-native)

    # Video & audio player
    mpv # media player (all formats)
    playerctl # media key control (play/pause/next)

    # PDF viewer
    zathura # vim-like PDF viewer
    poppler-utils # pdftotext, pdfinfo, pdfimages

    # MarkDown viewer
    inlyne # markdown renderer in gui

    # Archive tools
    zip # create zip archives
    unzip # extract zip archives
    p7zip # 7z support
    unrar # rar extraction
    # ouch # modern extract

    # Mount & notifications
    udiskie # auto-mount USB drives
    libnotify # desktop notifications (notify-send)

    # Media processing
    ffmpegthumbnailer # video thumbnails for file managers
  ];
}
