{pkgs, ...}: {
  home.packages = with pkgs; [
    # ──────────────────────────────────────────────
    # 📂 File & Directory Management
    # ──────────────────────────────────────────────
    eza # Modern ls with git status, icons, and tree support
    fd # Fast, user-friendly find alternative
    trash-cli # Safe delete with trash bin (prevents accidental rm)

    # ──────────────────────────────────────────────
    # 💾 Disk & System Inspection
    # ──────────────────────────────────────────────
    duf # Modern df with beautiful, readable output
    dust # Interactive du with tree visualization (very practical)
    lsof # List open files, sockets and ports

    # ──────────────────────────────────────────────
    # 🔎 Search, Text & Data Processing
    # ──────────────────────────────────────────────
    ripgrep # Extremely fast grep with regex support
    ripgrep-all # `rga`: ripgrep across PDF/zip/sqlite/docx/media metadata
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
    librespeed-cli # Speed test via free LibreSpeed servers (Go, no Ookla)
    ipcalc # IP address and subnet calculations

    # ──────────────────────────────────────────────
    # 🛠️ Git, API & Development
    # ──────────────────────────────────────────────
    just # Modern, simple command runner (better than make)
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

    # ──────────────────────────────────────────────
    # 🔐 Secrets & Passwords
    # ──────────────────────────────────────────────
    bitwarden-cli # Bitwarden CLI for API key & password management
  ];

  # ============================================================
  # Native Program Configurations
  # ============================================================
  programs = {
    bat = {
      enable = true;
      config = {
        theme = "ansi";
        style = "numbers,changes,header";
      };
    };

    yazi = {
      enable = true;
      enableFishIntegration = true;
      shellWrapperName = "y";
    };

    zoxide = {
      enable = true;
      enableFishIntegration = true;
      options = ["--cmd" "z"];
    };

    fzf = {
      enable = true;
      enableFishIntegration = true;
      defaultCommand = "fd --type f --strip-cwd-prefix --hidden --follow --exclude .git";
      defaultOptions = [
        "--height 55%"
        "--layout=reverse"
        "--border rounded"
        "--multi"
        "--color=fg:#cdd6f4,bg:#1e1e2e,hl:#f38ba8"
        "--color=fg+:#cdd6f4,bg+:#313244,hl+:#f38ba8"
        "--color=info:#cba6f7,prompt:#89b4fa,pointer:#f5e0dc"
      ];
    };

    carapace = {
      enable = true;
      enableFishIntegration = true;
    };

    btop.enable = true;
    bottom.enable = true;
    fastfetch.enable = true;
    lazygit.enable = true;
  };
}
