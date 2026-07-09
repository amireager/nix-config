{...}: {
  # Nvidia hybrid graphics
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    modesetting.enable = true;
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

  # Laptop power management
  services.tlp = {
    enable = true;
    settings = {
      cpu_scaling_governor_on_ac = "performance";
      cpu_scaling_governor_on_bat = "powersave";
      cpu_energy_perf_policy_on_ac = "performance";
      cpu_energy_perf_policy_on_bat = "balance_power";
      cpu_max_perf_on_bat = 70;
      cpu_boost_on_bat = 0;
      usb_autosuspend = 1;
      usb_timeout = 2;
      wifi_pwr_on_bat = "on";
      runtime_pm_on_bat = "auto";
    };
  };

  services.upower.enable = true;
}
