{
  pkgs,
  flakePath,
  ...
}: {
  # ============================================================
  # CORE SYSTEM — NixOS Foundation
  # ============================================================

  # === Nixpkgs ===
  # Workstation profile: allow proprietary firmware/drivers/apps when needed.
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

    # Binary caches — mirrors for reliable downloads.
    # Chinese mirrors help when direct access to cache.nixos.org is slow/blocked.
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
  # Disabled — not widely usable in Iran.
  networking.enableIPv6 = false;

  # === Firmware ===
  # Required for AMD CPU microcode updates and broader hardware support.
  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;

  # === Kernel ===
  # Latest kernel is useful for newer hardware, Wayland, and NVIDIA fixes.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Keep early boot output quiet unless something goes wrong.
  boot.initrd.verbose = false;

  # === Memory & Swap ===
  boot.kernel.sysctl = {
    # ZRAM optimization: higher swappiness makes compressed RAM swap more useful.
    "vm.swappiness" = 180;

    # Balanced cache reclaiming: avoid being too aggressive with filesystem cache.
    "vm.vfs_cache_pressure" = 50;
  };

  # ZRAM — compressed swap in RAM.
  zramSwap = {
    enable = true;
    memoryPercent = 25;
  };

  # === SSD Maintenance ===
  # Automatic TRIM for NVMe/SATA SSDs to prevent performance degradation.
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

  # === Fonts ===
  fonts.packages = with pkgs; [
    vazirmatn
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
  ];

  # === Essential System Packages ===
  # Keep only rescue/debug/system-wide tools here.
  # User applications and daily CLI tools belong in Home Manager.
  environment.systemPackages = with pkgs; [
    # Emergency / rescue
    vim
    git

    # Hardware inspection
    pciutils
    usbutils
    lshw
    dmidecode

    # Storage and boot inspection
    smartmontools
    nvme-cli
    efibootmgr

    # Sensors and thermal debugging
    lm_sensors
  ];

  # === NH — NixOS Management Wrapper ===
  # Rebuild: nh os switch
  # Test:    nh os test
  # Clean:   nh clean
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
    HandlePowerKey = "suspend";
    HandlePowerKeyLongPress = "poweroff";
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "lock";
    HandleLidSwitchDocked = "ignore";
  };

  # === Wayland Environment Variables ===
  environment.sessionVariables = {
    AVALONIA_PLATFORM = "Wayland";
    QT_QPA_PLATFORM = "wayland";
    NIXOS_OZONE_WL = "1";
  };

  # === AppImage Support ===
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # Required for AppImage mounting.
  boot.kernelModules = ["fuse"];

  # Set to your actual installed NixOS version; do not change after installation.
  system.stateVersion = "26.05";
}
