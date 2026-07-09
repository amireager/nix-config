{...}: {
  # Nvidia hybrid graphics
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    modesetting.enable = true;

    # Let Nvidia manage its own power (for laptop hybrid GPU)
    powerManagement.enable = true;
    powerManagement.finegrained = true;

    open = false;
    nvidiaSettings = true;
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
    };
  };

  # Laptop power management — TLP handles CPU, Nvidia handles its own GPU
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
      CPU_MAX_PERF_ON_BAT = 70;
      CPU_BOOST_ON_BAT = 0;
      USB_AUTOSUSPEND = 1;
      USB_TIMEOUT = 2;
      WIFI_PWR_ON_BAT = "on";
      RUNTIME_PM_ON_BAT = "auto";
      # Exclude Nvidia GPU from TLP — let nvidia driver manage it
      RUNTIME_PM_DRIVER_BLACKLIST = "nvidia nouveau";
    };
  };

  services.upower.enable = true;
}
