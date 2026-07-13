{
  pkgs,
  inputs,
  ...
}: {
  home.packages = [
    # ──────────────────────────────────────────────
    # Primary Browser — Recommended
    # ──────────────────────────────────────────────
    inputs.zen-browser.packages."${pkgs.stdenv.hostPlatform.system}".default

    # ──────────────────────────────────────────────
    # Secondary / Specialized Browsers
    # ──────────────────────────────────────────────
    pkgs.qutebrowser # Keyboard-driven (Vim-like), very lightweight
    pkgs.brave # Privacy + built-in adblock (good backup)

    # ──────────────────────────────────────────────
    # Optional / Niche
    # ──────────────────────────────────────────────
    # pkgs.librewolf           # Hardened Firefox (uncomment if you want max privacy)
    # pkgs.floorp              # Another Firefox fork with nice features
  ];

  # ──────────────────────────────────────────────
  # Make Zen the default browser
  # ──────────────────────────────────────────────
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = ["zen.desktop"];
      "x-scheme-handler/http" = ["zen.desktop"];
      "x-scheme-handler/https" = ["zen.desktop"];
      "application/x-extension-htm" = ["zen.desktop"];
      "application/x-extension-html" = ["zen.desktop"];
      "application/x-extension-shtml" = ["zen.desktop"];
      "application/xhtml+xml" = ["zen.desktop"];
      "application/x-extension-xhtml" = ["zen.desktop"];
      "application/x-extension-xht" = ["zen.desktop"];
    };
  };
}
