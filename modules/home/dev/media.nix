# Dev media tools — specialized, not for daily use
{pkgs, ...}: {
  home.packages = with pkgs; [
    # Image editing — lightweight
    pinta # simple image editor (like MS Paint but better)

    # PDF tools (CLI)
    poppler-utils # pdftotext, pdfinfo, pdfimages

    # Media processing (CLI)
    ffmpegthumbnailer # video thumbnails for file managers

    # Screen recording
    kooha # Wayland-native screen recorder (simple GUI)
  ];
}
