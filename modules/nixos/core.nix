{
  pkgs,
  flakePath,
  ...
}: {
  # ============================================================
  # CORE SYSTEM — NixOS Foundation
  # ============================================================

  # === Nixpkgs ===
  nixpkgs.config.allowUnfree = true;

  # === Nix Settings ===
  nix.settings = {
    experimental-features = ["nix-command" "flakes"];

    # Store optimization: deduplicate identical files in /nix/store.
    auto-optimise-store = true;

    # Nix database performance: reduce lock contention and improve reliability.
    use-sqlite-wal = true;

    # Build performance.
    max-jobs = "auto";
    cores = 0;

    # Network reliability for slower/unstable connections.
    connect-timeout = 10;
    download-attempts = 3;
    fallback = true;

    # Allow admin users to use trusted Nix features and binary caches.
    trusted-users = ["root" "@wheel"];

    # Binary caches — only signed caches.
    substituters = [
      "https://cache.nixos.org"
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
  networking.enableIPv6 = false;

  # === Firmware ===
  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;

  # === Kernel ===
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.initrd.verbose = false;

  # === Memory & Swap (Optimized for ZRAM) ===
  boot.kernel.sysctl = {
    "vm.swappiness" = 180;
    "vm.vfs_cache_pressure" = 50;
    "vm.page-cluster" = 0;
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
  };

  zramSwap = {
    enable = true;
    memoryPercent = 100;
  };

  # === SSD Maintenance ===
  services.fstrim = {
    enable = true;
    interval = "weekly";
  };

  # === Locale & Timezone ===
  time.timeZone = "Asia/Tehran";
  i18n.defaultLocale = "en_US.UTF-8";

  # Keyboard layout — US + Persian, toggle with Alt+Shift.
  services.xserver.xkb = {
    layout = "us,ir";
    options = "grp:alt_shift_toggle";
  };

  # === Fonts & Typography ===
  fonts = {
    packages = with pkgs; [
      vazirmatn
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      noto-fonts
      noto-fonts-cjk-sans
      twitter-color-emoji
      inter
    ];

    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = ["JetBrainsMono Nerd Font" "Vazirmatn" "Noto Sans Mono"];
        sansSerif = ["Inter" "Vazirmatn" "Noto Sans"];
        serif = ["Noto Serif" "Vazirmatn"];
        emoji = ["Twitter Color Emoji"];
      };
    };
  };

  # === Essential System Packages ===
  environment.systemPackages = with pkgs; [
    vim
    git
    pciutils
    usbutils
    lshw
    dmidecode
    smartmontools
    nvme-cli
    efibootmgr
    lm_sensors
  ];

  # === NH — NixOS Management Wrapper ===
  programs.nh = {
    enable = true;
    flake = flakePath;
    clean = {
      enable = true;
      extraArgs = "--keep-since 30d --keep 5";
    };
  };

  # === AppImage Support ===
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  boot.kernelModules = ["fuse"];

  # Set to your actual installed NixOS version; do not change after installation.
  system.stateVersion = "26.05";
}
