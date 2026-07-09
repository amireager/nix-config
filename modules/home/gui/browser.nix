{
  pkgs,
  inputs,
  ...
}: {
  home.packages = [
    # Default browser — Arc-like UX, vertical tabs
    inputs.zen-browser.packages."${pkgs.stdenv.hostPlatform.system}".default

    # Keyboard-driven browser — vim-like navigation
    pkgs.qutebrowser

    # Privacy-focused — built-in ad blocker & shields
    pkgs.brave

    # Thorium: download AppImage from https://github.com/Alex313031/Thorium/releases
    # Already supported via programs.appimage (enabled in core.nix)
  ];
}
