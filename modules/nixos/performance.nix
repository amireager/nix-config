{pkgs, ...}: {
  # ============================================================
  # PERFORMANCE — Store, Kernel, Memory, and Storage Tuning
  # ============================================================
  # These values are policy, not universal defaults. Hosts with different
  # latency, memory, storage, or kernel requirements can omit this module.

  nix = {
    settings = {
      # WAL is the upstream default and keeps concurrent Store operations from
      # serialising on the SQLite journal.
      use-sqlite-wal = true;

      # Ryzen 5 5500U exposes 12 threads. Keep the advertised build capacity
      # bounded instead of combining max-jobs=auto with cores=0, which can
      # oversubscribe every parallel builder with all available threads.
      max-jobs = 3;
      cores = 4;

      # Avoid stale tarball checks during normal locked-flake use. Transfer
      # concurrency, timeouts and attempts stay at Nix's maintained defaults.
      tarball-ttl = 604800;

      # A failed known substitute must not silently turn into a large source
      # build. Ordinary cache misses can still build normally.
      fallback = false;
    };

    # Deduplicate away from interactive builds. The pinned NixOS service runs
    # this with idle CPU/I/O priority and only while connected to AC power.
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
