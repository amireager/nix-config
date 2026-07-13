# media/core.nix — Daily & Lightweight Media Tools
{pkgs, ...}: {
  home.packages = with pkgs; [
    # ── Image Viewing & Management ──
    imv # Lightweight Wayland-native image viewer
    loupe # Modern GNOME image viewer (alternative to imv)
    nomacs # Advanced image viewer with editing tools

    # ── Video & Audio ──
    mpv # Best all-format media player
    playerctl # Control media players via keyboard/media keys
    celluloid # Nice GTK frontend for mpv (optional)

    # ── Document & Reading ──
    zathura # Minimalist Vim-like PDF viewer
    inlyne # Fast Markdown renderer (GUI)

    # ── Note Taking (Lightweight) ──
    # logseq           # Alternative to Obsidian (if you prefer outliner style)
    glow # Terminal Markdown viewer (already in CLI tools)

    # ── Capture & Input ──
    guvcview # Webcam app with controls
    wf-recorder # Wayland screen recorder (CLI)

    # ── Archive & File Management ──
    zip
    unzip
    p7zip
    unrar
    # ouch               # Modern unified archive tool (already in tools)

    # ── Auto-mount & Notifications ──
    udiskie # Auto-mount USB drives + notifications
    libnotify # notify-send command

    # ── Media Processing (Essential) ──
    ffmpeg # Universal media converter
    yt-dlp # Best YouTube & site downloader
    imagemagick # Powerful image manipulation
  ];
}
