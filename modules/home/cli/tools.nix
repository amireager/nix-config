{pkgs, ...}: {
  home.packages = with pkgs; [
    # === File and Disk Utilities ===
    duf # Modern df with beautiful, readable output
    dust # Interactive du with tree visualization (very practical)
    fd # Fast, user-friendly find alternative
    eza # Modern ls with git status, icons, and tree support
    # ouch # Simple unified tool for archive compression/decompression
    trash-cli # Safe delete with trash bin (prevents accidental rm)

    # === Text, Search and Data Processing ===
    ripgrep # Extremely fast grep with regex support
    jq # Powerful JSON processor
    yq-go # YAML processor (jq for YAML)
    sd # Intuitive find & replace (modern sed)

    # === System Inspection ===
    lsof # List open files, sockets and ports

    # === Network and Transfer ===
    curl # Classic and reliable HTTP client
    wget # Recursive downloads with resume support
    xh # Modern, clean HTTP client (daily use)
    aria2 # Fast multi-connection downloader (HTTP + Torrent)
    rsync # Efficient incremental file synchronization

    # === Network Diagnostics ===
    dnsutils # dig, nslookup, host
    doggo # Modern DNS client with DoH/DoT support
    mtr # Combined traceroute + ping with live stats
    gping # Ping with beautiful live graph
    whois # Domain and IP ownership lookup
    vnstat # Lightweight network traffic history (monthly usage)
    speedtest-cli # Official internet speed testing
    ipcalc # IP address and subnet calculations

    # === Productivity and Helpers ===
    just # Modern, simple command runner (better than make)
    glow # Terminal Markdown renderer
    gum # Beautiful interactive prompts, spinners, and choosers

    # === Additional Modern Tools ===
    bottom # Advanced system resource monitor
    ugrep # Powerful grep with regex and binary support
    gh-dash # GitHub dashboard TUI
    navi # Interactive cheatsheets for commands

    # === Additional file managers ===
    superfile # Modern terminal file manager
  ];

  # Program configurations
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
  programs.bottom.enable = true;
  programs.fastfetch.enable = true;
  programs.lazygit.enable = true;
}
# === Removed / Replaced Tools (Old list) ===
# lsd          # Replaced by eza (better git support)
# nload        # Replaced by btop + bandwhich
# bmon         # Replaced by btop + bandwhich
# iftop        # Replaced by bandwhich
# nethogs      # Replaced by bandwhich
# iotop        # Covered by btop
# socat        # Too low-level for daily use
# proxychains-ng # Niche use-case
# trippy       # Optional - mtr is sufficient for most users

