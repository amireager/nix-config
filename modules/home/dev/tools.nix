# Dev tools
# NOTE: All CLI/dev tools are consolidated in ../cli/tools.nix
# Add dev-specific packages here only if they don't belong in the general CLI set.
{pkgs, ...}: {
  home.packages = with pkgs; [
    # === Modern CLI Enhancements ===
    ast-grep # Structural code search & refactoring (like grep for AST)
    erdtree # Fast tree viewer with disk usage
    hexyl # Colorful hex viewer
    dasel # Query and edit JSON/YAML/TOML/XML/CSV
    grex # Generate regex from example texts

    # === Benchmarking & Watching ===
    hyperfine # Accurate command-line benchmarking
    watchexec # Execute commands when files change

    # === Code Analysis ===
    tokei # Fast code statistics (lines of code)

    # === GitHub & Workflow ===
    gh-dash # GitHub dashboard TUI
    navi # Interactive cheatsheets for commands

    # === File Transfer & Sync ===
    rclone # Sync with cloud providers (Google Drive, S3, etc.)
    magic-wormhole # Secure, simple P2P file transfer
  ];
}
# === Removed / Replaced Tools ===
# ripgrep-all  # Heavy, rarely needed (use ripgrep + specific tools)
# lsd          # Already using eza in tools.nix
# bmon / nload # Covered in tools

