{pkgs, ...}: {
  home.packages = with pkgs; [
    # ──────────────────────────────────────────────
    # 📂 File & Directory Management
    # ──────────────────────────────────────────────
    eza # Modern ls with git status, icons, and tree support
    fd # Fast, user-friendly find alternative
    superfile # Modern terminal file manager
    trash-cli # Safe delete with trash bin (prevents accidental rm)
    # ouch     # Simple unified tool for archive compression/decompression

    # ──────────────────────────────────────────────
    # 💾 Disk & System Inspection
    # ──────────────────────────────────────────────
    duf # Modern df with beautiful, readable output
    dust # Interactive du with tree visualization (very practical)
    bottom # Advanced system resource monitor
    lsof # List open files, sockets and ports

    # ──────────────────────────────────────────────
    # 🔎 Search, Text & Data Processing
    # ──────────────────────────────────────────────
    ripgrep # Extremely fast grep with regex support
    ugrep # Powerful grep with regex and binary support
    sd # Intuitive find & replace (modern sed)
    jq # Powerful JSON processor
    yq-go # YAML processor (jq for YAML)

    # ──────────────────────────────────────────────
    # 🌐 Network & Transfer
    # ──────────────────────────────────────────────
    curl # Classic and reliable HTTP client
    wget # Recursive downloads with resume support
    xh # Modern, clean HTTP client (daily use)
    aria2 # Fast multi-connection downloader (HTTP + Torrent)
    rsync # Efficient incremental file synchronization

    # ──────────────────────────────────────────────
    # 📡 Network Diagnostics
    # ──────────────────────────────────────────────
    dnsutils # dig, nslookup, host
    doggo # Modern DNS client with DoH/DoT support
    mtr # Combined traceroute + ping with live stats
    gping # Ping with beautiful live graph
    whois # Domain and IP ownership lookup
    vnstat # Lightweight network traffic history
    speedtest-cli # Official internet speed testing
    ipcalc # IP address and subnet calculations

    # ──────────────────────────────────────────────
    # 🛠️ Git, API & Development
    # ──────────────────────────────────────────────
    just # Modern, simple command runner (better than make)
    gh-dash # GitHub dashboard TUI
    delta # Syntax-highlighting pager for git diff/grep output

    # ──────────────────────────────────────────────
    # 🚀 Productivity, Cheatsheets & Terminal
    # ──────────────────────────────────────────────
    tlrc # Official tldr client in Rust (beautiful colors)
    navi # Interactive cheatsheets for commands
    glow # Terminal Markdown renderer
    gum # Beautiful interactive prompts, spinners, and choosers

    # ──────────────────────────────────────────────
    # ⌨️ Keyboard Flow & Media
    # ──────────────────────────────────────────────
    ttyper # Terminal-based typing practice (Rust, code support)
    tt # Minimalist terminal typing test
    cmus # Small, fast and powerful console music player
    yt-dlp # Command-line audio/video downloader
  ];

  # ============================================================
  # Native Program Configurations
  # ============================================================
  programs.bat = {
    enable = true;
    config = {
      theme = "ansi";
      style = "numbers,changes,header";
    };
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
