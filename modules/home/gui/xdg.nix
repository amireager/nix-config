{
  pkgs,
  config,
  ...
}: {
  # ============================================================
  # XDG Base Directory & Mime Applications
  # ============================================================

  xdg.userDirs = {
    enable = true;
    createDirectories = true;

    # === Simplified / Minimal User Directories ===
    # This removes the clutter from ~ (Home) and keeps only what's necessary.
    desktop = "${config.home.homeDirectory}/dsk";
    download = "${config.home.homeDirectory}/dl";
    documents = "${config.home.homeDirectory}/doc";
    music = "${config.home.homeDirectory}/media/audio";
    pictures = "${config.home.homeDirectory}/media/img";
    videos = "${config.home.homeDirectory}/media/vid";
    templates = "${config.home.homeDirectory}/doc/templates";
    publicShare = "${config.home.homeDirectory}/pub";

    extraConfig = {
      XDG_DEV_DIR = "${config.home.homeDirectory}/dev"; # Developer workspace
    };
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # Browser
      "text/html" = ["zen-beta.desktop"];
      "x-scheme-handler/http" = ["zen-beta.desktop"];
      "x-scheme-handler/https" = ["zen-beta.desktop"];
      "application/x-extension-htm" = ["zen-beta.desktop"];
      "application/x-extension-html" = ["zen-beta.desktop"];
      "application/x-extension-shtml" = ["zen-beta.desktop"];
      "application/xhtml+xml" = ["zen-beta.desktop"];
      "application/x-extension-xhtml" = ["zen-beta.desktop"];
      "application/x-extension-xht" = ["zen-beta.desktop"];

      # Images
      "image/png" = ["imv.desktop"];
      "image/jpeg" = ["imv.desktop"];
      "image/gif" = ["imv.desktop"];
      "image/webp" = ["imv.desktop"];
      "image/svg+xml" = ["imv.desktop"];

      # Video / Audio
      "video/mp4" = ["mpv.desktop"];
      "video/x-matroska" = ["mpv.desktop"];
      "video/webm" = ["mpv.desktop"];
      "audio/mpeg" = ["mpv.desktop"];
      "audio/flac" = ["mpv.desktop"];

      # PDF
      "application/pdf" = ["org.pwmt.zathura.desktop"];

      # Text & Code (Opens via Terminal + Neovim)
      "text/plain" = ["nvim.desktop"];
      "text/markdown" = ["marker.desktop" "nvim.desktop"];
      "application/json" = ["nvim.desktop"];
      "text/x-csrc" = ["nvim.desktop"];
      "text/x-chdr" = ["nvim.desktop"];
      "text/x-python" = ["nvim.desktop"];
      "text/x-shellscript" = ["nvim.desktop"];

      # Archives (Use file manager or archive tool)
      "application/zip" = ["thunar.desktop"];
      "application/x-tar" = ["thunar.desktop"];
      "application/x-bzip2" = ["thunar.desktop"];
      "application/x-gzip" = ["thunar.desktop"];

      # Directories
      "inode/directory" = ["thunar.desktop"];
    };
  };

  # Ensure the necessary packages are installed
  home.packages = with pkgs; [
    marker # Modern, fast markdown editor/renderer
  ];

  # Dynamically generate a `.desktop` file for Neovim so the file manager knows how to launch it
  xdg.desktopEntries.nvim = {
    name = "Neovim";
    genericName = "Text Editor";
    exec = "kitty -e nvim %F"; # Open kitty and run nvim
    terminal = false;
    categories = ["Utility" "TextEditor"];
    mimeType = ["text/plain" "application/x-zerosize"];
  };
}
