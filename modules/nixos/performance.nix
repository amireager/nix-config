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

      # Cargo's locked niri dependency uses builtins.fetchGit with an exact
      # revision, but Nix still probes the repository's HEAD branch. In
      # networks that cannot resolve github.com, refreshing that irrelevant
      # branch ref emits a fatal+expired-cache warning even when the pinned
      # commit is already cached and the build can continue. Keep the cached
      # Git ref fresh for a year to avoid these needless probes. Transfer
      # concurrency and attempts stay at Nix's maintained defaults; the
      # connect and stall timeouts live in `modules/nixos/core.nix`.
      tarball-ttl = 31536000;

      # Fail fast on a broken binary cache instead of silently starting a
      # huge source build. The exact semantics, measured on Nix 2.35:
      #
      #   * cache miss (clean 404)  -> Nix builds it from source as usual
      #   * cache unreachable        -> warning only, the next cache is used
      #   * cache returns an error   -> the build fails
      #
      # The third case only becomes fatal for paths that exist in NO other
      # cache — which is exactly the set where a source build would be
      # expensive (niri, noctalia, zen-browser). A transient hiccup on
      # niri.cachix.org therefore fails in seconds instead of starting a
      # forty-minute compile. See docs/09-rules.md and `nix-cache-doctor`.
      fallback = false;
    };

    # Deduplicate away from interactive builds. The pinned NixOS service runs
    # this with idle CPU/I/O priority and only while connected to AC power.
    #
    # `dates` is a systemd.time(7) calendar specification, not a
    # "weekly"/"monthly" keyword. `weekly` would mean "Monday 00:00"; this
    # pins the run to Monday 03:45 instead, which is the nixpkgs default
    # hour. The service is Persistent, so a machine that was off at that
    # time runs it on the next boot.
    optimise = {
      automatic = true;
      dates = ["Mon *-*-* 03:45:00"];
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
      "boot.shell_on_fail"
      "udev.log_level=3"
      "systemd.show_status=true"
      # No "splash": Plymouth is not enabled on this host, so the kernel
      # parameter would be handed to a splash screen that does not exist.
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
