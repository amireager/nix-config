{mkDevShell, pkgs, ...}:
# Heavy, occasionally-used media tooling. Daily playback/viewing apps (mpv,
# imv, zathura, ffmpeg, ffmpegthumbnailer) deliberately stay at home level so
# the desktop works without entering a shell.
mkDevShell {
  name = "media";
  icon = "🎬";
  description = "ffmpeg-full, vips, ImageMagick, OCR, PDF";

  packages = with pkgs; [
    # Image processing
    imagemagick # `magick` (v7); `convert` is deprecated upstream
    vips # 3-10x faster than ImageMagick for batch work, less RAM
    oxipng # Lossless PNG optimizer (Rust)
    jpegoptim # JPEG optimizer
    svgcleaner # SVG minifier
    gifski # High-quality GIF encoder

    # Video / audio processing
    ffmpeg-full # Full codec set (home level carries plain ffmpeg)
    mediainfo # Technical metadata inspection
    mkvtoolnix-cli # Matroska muxing/remuxing

    # PDF & documents
    pdfarranger # GUI: reorder/split/merge PDF pages
    qpdf # CLI: lossless PDF transformations
    ocrmypdf # Add a searchable OCR text layer
    tesseract # OCR engine used by ocrmypdf

    # Raster / vector editors
    pinta # Lightweight Paint.NET-style editor
    marker # GTK markdown editor

    # Capture
    guvcview # Webcam capture & controls
  ];

  tips = [
    {key = "Convert"; cmd = "magick in.png out.webp";}
    {key = "Fast batch"; cmd = "vips copy in.jpg out.webp";}
    {key = "Optimize"; cmd = "oxipng -o4 *.png / jpegoptim *.jpg";}
    {key = "Inspect"; cmd = "mediainfo file.mkv";}
    {key = "OCR a PDF"; cmd = "ocrmypdf in.pdf out.pdf";}
  ];
}
