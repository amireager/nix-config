{...}: {
  # ============================================================
  # LAPTOP POWER MANAGEMENT
  # ============================================================

  # Power button & Lid Switch
  services.logind.settings.Login = {
    HandlePowerKey = "suspend";
    HandlePowerKeyLongPress = "poweroff";
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "lock";
    HandleLidSwitchDocked = "ignore";
  };

  # TLP
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
      RUNTIME_PM_DRIVER_BLACKLIST = "nvidia nouveau";
    };
  };

  services.power-profiles-daemon.enable = false;
  services.upower.enable = true;
}
