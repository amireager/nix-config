{...}: {
  # ============================================================
  # LAPTOP POWER MANAGEMENT
  # ============================================================

  services.logind.settings.Login = {
    HandlePowerKey = "suspend";
    HandlePowerKeyLongPress = "poweroff";
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "lock";
    HandleLidSwitchDocked = "ignore";
  };

  # auto-cpufreq — automatic CPU speed & power optimization
  services.auto-cpufreq.enable = true;

  services.power-profiles-daemon.enable = false;

  services.upower.enable = true;
}
