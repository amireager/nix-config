_: {
  # ============================================================
  # SECURITY — Balanced defaults for a personal laptop
  # ============================================================
  # Isolation of untrusted code is `box`, not Firejail or OpenSnitch.

  # === Inbound Firewall ===
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [];
    allowedUDPPorts = [];

    # Loose reverse-path filtering stays compatible with VPN/TUN paths.
    checkReversePath = "loose";
  };

  # === Privilege Separation & Mandatory Access Control ===
  security = {
    sudo.enable = false;

    sudo-rs = {
      enable = true;
      execWheelOnly = true;
      wheelNeedsPassword = true;
    };

    apparmor = {
      enable = true;
      # New profiles confine a process on its next launch, not mid-session.
      killUnconfinedConfinables = false;
    };
  };

  services = {
    # Firmware and UEFI security updates through LVFS-supported hardware.
    fwupd.enable = true;

    # Home-laptop compromise: reject obvious storage+keyboard BadUSB
    # composites, then allow everything else without approval prompts.
    usbguard = {
      enable = true;
      presentDevicePolicy = "allow";
      rules = ''
        allow with-interface equals { 08:*:* }
        allow with-interface equals { 03:*:* }
        allow with-interface equals { 06:*:* }
        allow with-interface equals { 02:*:* }
        allow with-interface equals { 0A:*:* }
        allow with-interface equals { FF:*:* }
        allow with-interface equals { E0:*:* }

        reject with-interface all-of { 08:*:* 03:00:* }
        reject with-interface all-of { 08:*:* 03:01:* }

        allow
      '';
    };
  };

  boot = {
    kernel.sysctl = {
      "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
      "kernel.kptr_restrict" = 2;
      "kernel.dmesg_restrict" = 1;
      "kernel.sysrq" = 0;
      "dev.tty.legacy_tiocsti" = 0;
    };

    tmp.cleanOnBoot = true;
  };
}
