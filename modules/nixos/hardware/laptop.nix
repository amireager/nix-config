_: {
  # ============================================================
  # LAPTOP POWER MANAGEMENT
  # ============================================================

  services = {
    logind.settings.Login = {
      HandlePowerKey = "suspend";
      HandlePowerKeyLongPress = "poweroff";
      HandleLidSwitch = "suspend";
      HandleLidSwitchExternalPower = "lock";
      HandleLidSwitchDocked = "ignore";
    };

    # auto-cpufreq — automatic CPU speed & power optimization
    auto-cpufreq.enable = true;
    power-profiles-daemon.enable = false;
    upower.enable = true;
  };
}
