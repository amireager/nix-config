{
  pkgs,
  flakePath,
  inputs ? {},
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

    # GC resilience: keep build outputs and derivations of live profiles/devShells from being collected.
    keep-outputs = false;
    keep-derivations = false;

    # Store optimization: deduplicate identical files in /nix/store.
    auto-optimise-store = true;

    # Nix database performance: reduce lock contention and improve reliability.
    use-sqlite-wal = true;

    # Build performance.
    max-jobs = "auto";
    cores = 0;

    # Network reliability and download concurrency for slower/unstable connections.
    http-connections = 50;
    tarball-ttl = 604800; # Cache downloaded flake tarballs for 7 days to speed up evaluation
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

  # === Automatic Store Deduplication ===
  nix.optimise = {
    automatic = true;
    dates = ["weekly"];
  };

  # === IPv6 ===
  networking.enableIPv6 = false;

  # === Firmware ===
  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;

  # === Fast & Silent Boot Architecture ===
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    initrd.verbose = false;
    initrd.systemd.enable = true;
    consoleLogLevel = 4; # Show KERN_WARNING + errors so we can see hangs
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "udev.log_level=3"
      # systemd.show_status keeps the boot log visible even behind splash,
      # so we can diagnose where the boot hangs.
      "systemd.show_status=true"
    ];
    loader.timeout = 1;
  };

  # === Service & Shutdown Timeouts ===
  # Speed up shutdown: default 90s -> 10s, prevent 2-minute stalls.
  systemd.settings.Manager.DefaultTimeoutStopSec = "10s";
  # Do not wait for network at boot -- services that need it will wait on their own.
  systemd.services.NetworkManager-wait-online.enable = false;

  # === OOM Daemon ===
  systemd.oomd.enable = true;
  systemd.oomd.enableUserSlices = true;

  # === Memory, Swap & I/O Responsiveness (Optimized for ZRAM + NVMe) ===
  boot.kernel.sysctl = {
    "vm.swappiness" = 180;
    "vm.vfs_cache_pressure" = 50;
    "vm.page-cluster" = 0;
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
    "vm.dirty_background_ratio" = 5;
    "vm.dirty_ratio" = 10;
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

  # === Journald Log Limitation (Keeps system storage clean) ===
  services.journald.extraConfig = ''
    SystemMaxUse=250M
    SystemMaxFileSize=50M
    MaxRetentionSec=1month
  '';

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
      # Latin
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      inter

      # Persian
      # Vazirmatn is the better UI face, Sahel is noticeably heavier and so
      # reads better as terminal fallback — see the note under fontconfig.
      vazirmatn
      sahel-fonts
      samim-fonts

      # Coverage
      noto-fonts
      noto-fonts-cjk-sans
      twitter-color-emoji
    ];

    fontconfig = {
      enable = true;
      defaultFonts = {
        # No true Persian monospace exists — Vazir Code was discontinued and
        # is not in nixpkgs. Every Persian face here is proportional, so the
        # terminal squeezes it into fixed cells and thin weights come out
        # hollow. Sahel is the heaviest of the maintained families, which is
        # why it leads the monospace fallback rather than Vazirmatn.
        monospace = [
          "JetBrainsMono Nerd Font"
          "Sahel"
          "Vazirmatn"
          "Noto Sans Mono"
        ];
        sansSerif = ["Inter" "Vazirmatn" "Noto Sans"];
        serif = ["Noto Serif" "Vazirmatn"];
        emoji = ["Twitter Color Emoji"];
      };

      # No global matrix scaling here on purpose. An earlier version scaled
      # Sahel 1.15x at the fontconfig level, which applied everywhere — GTK,
      # the browser, the editor — and compounded with the per-font `scale`
      # WezTerm already applies, leaving Latin looking small next to it.
      # Size matching belongs in the terminal config, where the cell grid is.
      localConf = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
        <fontconfig>
          <!-- Hinting and antialiasing matter more for Persian than Latin:
               the strokes are thinner and the curves tighter. -->
          <match target="font">
            <edit name="antialias" mode="assign"><bool>true</bool></edit>
            <edit name="hinting" mode="assign"><bool>true</bool></edit>
            <edit name="hintstyle" mode="assign"><const>hintslight</const></edit>
            <edit name="rgba" mode="assign"><const>rgb</const></edit>
            <edit name="lcdfilter" mode="assign"><const>lcddefault</const></edit>
            <edit name="autohint" mode="assign"><bool>false</bool></edit>
          </match>

          <!-- Persian text should never fall back to a Latin-only face. -->
          <match target="pattern">
            <test name="lang" compare="contains"><string>fa</string></test>
            <edit name="family" mode="prepend" binding="strong">
              <string>Sahel</string>
            </edit>
          </match>
        </fontconfig>
      '';
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
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # === NH — NixOS Management Wrapper ===
  programs.nh = {
    enable = true;
    flake = flakePath;
    clean = {
      enable = true;
      extraArgs = "--keep-since 10d --keep 10";
    };
  };

  # === AppImage Support ===
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # === Dynamic Libraries (NixLD) ===
  # Allows running unpatched standard Linux binaries (like downloaded precompiled tools)
  programs.nix-ld = {
    enable = true;
  };

  # === A typo is a typo ===
  # Off explicitly, not left to its default. The default is
  # `pathExists programs.sqlite`, which is true whenever nixpkgs arrives as a
  # channel tarball — so this can switch itself on from underneath you.
  #
  # It installs the same kind of command_not_found handler as the nix-index
  # fish integration (disabled in modules/home/dev/nix-tools.nix), and fish
  # explicitly looks for /run/current-system/sw/bin/command-not-found. Turning
  # off one and leaving the other would just move the pause somewhere else.
  #
  # With both off, a mistyped command says so and stops:
  #     $ caler
  #     fish: Unknown command: caler
  programs.command-not-found.enable = false;

  boot.kernelModules = ["fuse"];

  # Set to your actual installed NixOS version; do not change after installation.
  system.stateVersion = "26.05";

  # === Container Runtime (Podman) ===
  # Daemonless rootless container engine for isolated test environments.
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };
}
