{
  pkgs,
  inputs,
  flakePath,
  ...
}: {
  # ============================================================
  # CORE SYSTEM — NixOS Foundation
  # ============================================================

  # === Nix Settings ===
  nixpkgs.config.allowUnfree = true;
  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    auto-optimise-store = true;

    # Binary caches — mirrors for reliable downloads
    # Chinese mirrors help when direct access to cache.nixos.org is slow/blocked
    substituters = [
      "https://cache.nixos.org"
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://niri.cachix.org"
      "https://noctalia.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  # === IPv6 ===
  # Disabled — not widely usable in Iran
  networking.enableIPv6 = false;

  # === Firmware ===
  # Required for AMD CPU microcode updates and hardware support
  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;

  # === Kernel ===
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # === Memory & Swap ===
  boot.kernel.sysctl = {
    # ZRAM optimization: higher swappiness = more use of compressed RAM swap
    # Default 60 is too low for ZRAM — 180 is recommended by ZRAM docs
    "vm.swappiness" = 180;

    # How aggressively the kernel reclaims cache memory
    # 50 = balanced (not too aggressive, not too lazy)
    "vm.vfs_cache_pressure" = 50;
  };

  # ZRAM — compressed swap in RAM (25% of 16GB = ~4GB compressed)
  # Much faster than disk swap, no SSD wear
  zramSwap = {
    enable = true;
    memoryPercent = 25;
  };

  # === SSD Maintenance ===
  # Automatic TRIM for NVMe SSD — prevents performance degradation over time
  services.fstrim = {
    enable = true;
    interval = "weekly"; # run every week
  };

  # === Locale & Timezone ===
  time.timeZone = "Asia/Tehran";
  i18n.defaultLocale = "en_US.UTF-8";

  # Keyboard layout — US + Persian, toggle with Alt+Shift
  services.xserver.xkb = {
    layout = "us,ir";
    options = "grp:alt_shift_toggle";
  };

  # === Fonts ===
  fonts.packages = with pkgs; [
    vazirmatn          # Persian/Farsi font (Google)
    nerd-fonts.jetbrains-mono  # Nerd Font for terminal & dev icons
    nerd-fonts.fira-code       # Alternative Nerd Font
  ];

  # === Essential System Packages ===
  environment.systemPackages = with pkgs; [
    vim          # text editor (always needed)
    git          # version control
    gh           # GitHub CLI
    pciutils     # lspci — hardware inspection
  ];

  # === NH — NixOS Management Wrapper ===
  # Rebuild: nh os switch
  # Test:    nh os test
  # Clean:   nh clean (auto, 30 days / 5 generations)
  programs.nh = {
    enable = true;
    flake = flakePath;
    clean = {
      enable = true;
      extraArgs = "--keep-since 30d --keep 5";
    };
  };

  # === Power Button & Lid Switch ===
  services.logind.settings.Login = {
    HandlePowerKey = "suspend";         # short press → suspend
    HandlePowerKeyLongPress = "poweroff"; # long press → power off
    HandleLidSwitch = "suspend";        # close lid → suspend
    HandleLidSwitchExternalPower = "lock"; # lid + AC → lock screen
    HandleLidSwitchDocked = "ignore";   # lid + dock → ignore (external display)
  };

  # === Wayland Environment Variables ===
  environment.sessionVariables = {
    AVALONIA_PLATFORM = "Wayland";  # Avalonia UI framework
    QT_QPA_PLATFORM = "wayland";    # Qt applications
    NIXOS_OZONE_WL = "1";          # Electron apps (VS Code, etc.)
  };

  # === AppImage Support ===
  programs.appimage = {
    enable = true;
    binfmt = true; # auto-run .AppImage files
  };
  boot.kernelModules = ["fuse"]; # required for AppImage mounting

  # ⚠️ Set to your ACTUAL installed NixOS version — do NOT change after install
  system.stateVersion = "26.05";
}
