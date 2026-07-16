{...}: {
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    setSessionVariables = true;
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

      # Video / Audio
      "video/mp4" = ["mpv.desktop"];
      "video/x-matroska" = ["mpv.desktop"];
      "video/webm" = ["mpv.desktop"];
      "audio/mpeg" = ["mpv.desktop"];
      "audio/flac" = ["mpv.desktop"];

      # PDF
      "application/pdf" = ["org.pwmt.zathura.desktop"];

      # Directories
      "inode/directory" = ["thunar.desktop"];
    };
  };
}
