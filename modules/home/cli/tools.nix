{pkgs, ...}: {
  home.packages = with pkgs; [
    # File & disk utilities
    duf          # modern df replacement with color
    erdtree      # fast directory tree + size
    fd           # fast find alternative
    eza          # modern ls with icons & git
    yazi         # terminal file manager
    glow         # markdown renderer in terminal

    # Text & search
    bat          # cat with syntax highlighting
    ripgrep      # fast grep alternative
    jq           # JSON processor
    sd           # sed alternative (simpler syntax)

    # System monitoring
    btop         # system monitor (TUI)
    fastfetch    # fast system info
    iotop        # I/O monitoring
    procs        # modern ps alternative
    bandwhich    # bandwidth per process

    # Network & transfer
    xh           # modern HTTP client (like httpie)
    rsync        # file sync & transfer

    # Data & format
    hexyl        # hex viewer
    file         # file type detection
    grex         # regex generator from examples
    tailspin     # log file viewer with highlighting

    # Productivity & dev helpers
    lazygit      # git TUI
    navi         # command cheatsheet with fuzzy search
    hyperfine    # benchmarking tool
    just         # modern make alternative
    gh-dash      # GitHub dashboard (TUI)
    tokei        # code statistics (lines, files)
    watchexec    # file watcher & command runner
    difftastic   # structural diff tool
  ];

  programs.bat = {
    enable = true;
    config = {
      theme = "ansi";
      style = "numbers,changes,header";
    };
  };

  programs.tealdeer = {
    enable = true;
    settings.updates.auto_update = true;
  };

  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    shellWrapperName = "y";
  };

  programs.btop.enable = true;
  programs.fastfetch.enable = true;
  programs.lazygit.enable = true;
}
