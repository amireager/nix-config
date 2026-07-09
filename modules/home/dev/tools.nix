{pkgs, ...}: {
  home.packages = with pkgs; [
    # System monitoring
    iotop dust bandwhich erdtree procs

    # CLI utilities
    sd xh rsync file grex hexyl tailspin
    navi hyperfine just gh-dash

    # Dev tools
    tokei
    watchexec
    difftastic
  ];
}
