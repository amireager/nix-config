{pkgs, ...}: {
  home.packages = with pkgs; [
    imv
    mpv
    playerctl
    zathura
    poppler-utils
    zip unzip p7zip unrar
    udiskie
    ffmpegthumbnailer
    libnotify
  ];
}
