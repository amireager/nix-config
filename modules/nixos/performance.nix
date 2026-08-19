{pkgs, ...}: {
  # ============================================================
  # PERFORMANCE — Store, Kernel, Memory, and Storage Tuning
  # ============================================================
  # These values are policy, not universal defaults. Hosts with different
  # latency, memory, storage, or kernel requirements can omit this module.

  nix = {
    settings = {
      # Deduplicate identical files and reduce database lock contention.
      auto-optimise-store = true;
      use-sqlite-wal = true;

      # Use all available build capacity unless an individual build limits it.
      max-jobs = "auto";
      cores = 0;

      # Preserve the existing fetch concurrency and retry behaviour.
      http-connections = 50;
      tarball-ttl = 604800;
      connect-timeout = 10;
      download-attempts = 3;
      fallback = true;
    };

    optimise = {
      automatic = true;
      dates = ["weekly"];
    };
  };

  # Low-latency kernel plus observable, quiet boot behaviour. The bootloader
  # itself remains host-owned under hosts/<name>/default.nix.
  boot = {
    kernelPackages = pkgs.linuxPackages_zen;
    initrd = {
      verbose = false;
      systemd.enable = true;
    };
    consoleLogLevel = 4;
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "udev.log_level=3"
      "systemd.show_status=true"
    ];
    kernel.sysctl = {
      "vm.swappiness" = 180;
      "vm.vfs_cache_pressure" = 50;
      "vm.page-cluster" = 0;
      "vm.watermark_boost_factor" = 0;
      "vm.watermark_scale_factor" = 125;
      "vm.dirty_background_ratio" = 5;
      "vm.dirty_ratio" = 10;
    };
  };

  # Keep shutdown responsive without using the unsafe former 10-second limit.
  systemd = {
    settings.Manager.DefaultTimeoutStopSec = "30s";
    oomd = {
      enable = true;
      enableUserSlices = true;
    };
  };

  zramSwap = {
    enable = true;
    memoryPercent = 100;
  };

  services.fstrim = {
    enable = true;
    interval = "weekly";
  };
}
