_: {
  # ============================================================
  # LAPTOP — Power, battery safety and disk health
  # ============================================================

  services = {
    logind.settings.Login = {
      HandlePowerKey = "suspend";
      HandlePowerKeyLongPress = "poweroff";
      HandleLidSwitch = "suspend";
      HandleLidSwitchExternalPower = "suspend";
      HandleLidSwitchDocked = "ignore";
    };

    auto-cpufreq = {
      enable = true;
      settings = {
        charger = {
          governor = "performance";
          turbo = "auto";
        };
        battery = {
          governor = "powersave";
          turbo = "never";
        };
      };
    };

    power-profiles-daemon.enable = false;

    upower = {
      enable = true;
      usePercentageForPolicy = true;
      percentageLow = 20;
      percentageCritical = 10;
      percentageAction = 5;
      criticalPowerAction = "PowerOff";
    };

    smartd = {
      enable = true;
      autodetect = true;
      notifications.systembus-notify.enable = true;
    };
  };
}
