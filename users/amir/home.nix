{...}: {
  imports = [
    # ==========================================
    # 1. CLI Tools & Shells (Explicitly Imported)
    # ==========================================
    ../../modules/home/cli/fish.nix
    ../../modules/home/cli/git.nix
    ../../modules/home/cli/tmux.nix
    ../../modules/home/cli/zellij.nix
    ../../modules/home/cli/tools.nix

    # ==========================================
    # 2. Development Environments & Tools
    # ==========================================
    ../../modules/home/dev/nvim
    ../../modules/home/dev/nix-tools.nix

    # ==========================================
    # 3. GUI & Wayland / Niri Desktop Environment
    # ==========================================
    ../../modules/home/gui/browser.nix
    ../../modules/home/gui/media.nix
    ../../modules/home/gui/niri
    ../../modules/home/gui/terminal.nix
    ../../modules/home/gui/wayland.nix
    ../../modules/home/gui/xdg.nix

    # ==========================================
    # 4. Theming (GTK & Noctalia)
    # ==========================================
    ../../modules/home/theme/gtk.nix
    ../../modules/home/theme/noctalia.nix
  ];

  home.username = "amir";
  home.homeDirectory = "/home/amir";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}
