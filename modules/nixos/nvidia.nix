# ============================================================
# NVIDIA HYBRID GRAPHICS — Acer Aspire A715-42G
# GPU: GTX 1650 Mobile (Turing) + AMD Lucienne (Integrated)
# ============================================================
# PRIME offload mode: AMD iGPU renders by default,
# Nvidia GPU activates only when explicitly requested
# (e.g. __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia <app>)
#
# First boot workaround:
# If nvidia-x11 fails to download (403 error in Iran), temporarily switch to:
#   hardware.nvidia.open = false;
#   # OR use nouveau for first boot:
#   services.xserver.videoDrivers = ["nouveau"];
# After first boot, enable proxy and rebuild with open=true.
{...}: {
  # Nvidia driver
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    # Open-source kernel modules (Turing+ / RTX 20 & GTX 16 series and newer)
    # Recommended by Nvidia since driver 560. Better suspend/resume, Wayland support.
    open = true;

    # Modesetting required for Wayland compositors (niri, Sway, etc.)
    modesetting.enable = true;

    # Power management for hybrid GPU (laptop)
    # finegrained = auto power-off Nvidia GPU when not in use (huge battery savings)
    powerManagement.enable = true;
    powerManagement.finegrained = true;

    # Don't install nvidia-settings GUI (X11 only, useless on Wayland/niri)
    nvidiaSettings = false;

    # PRIME configuration — hybrid offload mode
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true; # adds nvidia-offload command
      };
      # Bus IDs for Acer Aspire A715-42G
      amdgpuBusId = "PCI:4:0:0"; # AMD Lucienne (integrated)
      nvidiaBusId = "PCI:1:0:0"; # GTX 1650 (discrete)
    };
  };

  # Kernel parameters for Nvidia + Wayland + power management
  boot.kernelParams = [
    # Required for Wayland with Nvidia
    "nvidia-drm.modeset=1"

    # Fine-grained power management (auto power-off GPU when idle)
    "nvidia.NVreg_DynamicPowerManagement=0x02"

    # Suspend/resume: preserve video memory across sleep
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
  ];

  # Suspend/resume handled by powerManagement.enable = true
  # No extra service needed — nvidia driver handles it automatically

  # Laptop power management — TLP handles CPU, Nvidia handles its own GPU
  services.tlp = {
    enable = true;
    settings = {
      # CPU governor
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      # Energy performance policy (EPP)
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";

      # On battery: limit CPU to 70% to save power, disable turbo boost
      CPU_MAX_PERF_ON_BAT = 70;
      CPU_BOOST_ON_BAT = 0;

      # USB auto-suspend (save power on idle USB devices)
      USB_AUTOSUSPEND = 1;
      USB_TIMEOUT = 2;

      # WiFi power saving on battery
      WIFI_PWR_ON_BAT = "on";

      # Runtime power management on battery
      RUNTIME_PM_ON_BAT = "auto";

      # Exclude Nvidia GPU from TLP — let nvidia driver manage it
      RUNTIME_PM_DRIVER_BLACKLIST = "nvidia nouveau";
    };
  };

  # Disable power-profiles-daemon (conflicts with TLP)
  services.power-profiles-daemon.enable = false;

  # UPower for battery monitoring (required by many desktop environments)
  services.upower.enable = true;
}
