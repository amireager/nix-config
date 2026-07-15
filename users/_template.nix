# ============================================================
# USER TEMPLATE - Copy and customize for new users
# ============================================================
# Usage:
# 1. Copy this file to users/<username>/default.nix
# 2. Customize the values below
# 3. Add to flake.nix: userModules.<username> = [./users/<username>];

{...}: {
  imports = [
    ../../modules/home
  ];

  # Customize these values
  home.username = "username";                    # Change to your username
  home.homeDirectory = "/home/username";         # Change to your home path
  home.stateVersion = "26.05";                   # Don't change after first setup
  programs.home-manager.enable = true;

  # Optional: Add user-specific customizations
  # home.packages = with pkgs; [ ... ];
  # programs.nvim.enable = true;  # Override defaults
  # etc.
}
