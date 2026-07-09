{pkgs, ...}: {
  home.packages = with pkgs; [
    # System monitoring & profiling
    iotop        # disk I/O monitoring per process
    erdtree      # fast directory tree with sizes
    bandwhich     # bandwidth usage per process
    procs        # modern ps with tree view

    # CLI utilities
    sd           # sed alternative (simpler syntax)
    xh           # modern HTTP client (like httpie)
    rsync        # file sync & remote transfer
    file         # detect file type by magic bytes
    grex         # generate regex from examples
    hexyl        # hex viewer for binary files
    tailspin     # log viewer with auto-highlighting
    navi         # interactive command cheatsheet
    hyperfine    # CLI benchmarking tool
    just         # modern make/command runner
    gh-dash      # GitHub PR/issue dashboard (TUI)

    # Dev tools
    tokei        # count lines of code by language
    watchexec    # run commands on file change
    difftastic   # structural diff (syntax-aware)
  ];
}
