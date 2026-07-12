{pkgs, ...}: {
  home.packages = with pkgs; [
    # File and disk utilities
    duf # Modern df replacement with readable output
    dust # Modern du replacement for disk usage analysis
    fd # Fast and user-friendly find replacement
    eza # Modern ls replacement with git and tree support
    lsd # Alternative modern ls with polished icons and config support
    ouch # Unified archive compression/decompression tool
    glow # Terminal markdown renderer
    trash-cli # Safe trash management from the command line

    # Text, search, and data
    ripgrep # Fast grep replacement
    jq # JSON processor
    yq-go # YAML processor
    sd # Simple and fast sed replacement
    jless # Interactive JSON viewer
    jc # Convert classic command output to JSON

    # System inspection
    procs # Modern ps replacement
    bandwhich # Per-process bandwidth monitor
    lsof # List open files, sockets, and ports
    psmisc # pstree, killall, fuser, and related process tools

    # Network and transfer
    curl # Classic HTTP client
    wget # Recursive and resumable downloader
    xh # Modern HTTP client
    aria2 # Fast multi-protocol downloader
    rsync # File synchronization and transfer

    # Network diagnostics
    dnsutils # dig, nslookup, host
    doggo # Modern DNS client
    mtr # Realtime traceroute and ping combined
    whois # Domain and IP ownership lookup
    socat # Socket relay and network debugging toolbox
    proxychains-ng # Route CLI applications through SOCKS/HTTP proxies

    # Background task management
    pueue # Queue and manage parallel background tasks

    # Data and file inspection
    file # File type detection
    tailspin # Log viewer with highlighting

    # Productivity and dev helpers
    just # Modern command runner
    difftastic # Structural diff tool
    gum # Interactive shell scripts (prompts, spinners, choose)
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
