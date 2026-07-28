{pkgs, ...}: {
  # ============================================================
  # SECURITY — Hardening, Sandboxing & Application Isolation
  # ============================================================

  # === Firewall ===
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [];
    allowedUDPPorts = [];
    # Drop packets with invalid headers to prevent basic network scans/attacks
    checkReversePath = "loose";
  };

  # === Modern, Memory-Safe Sudo (sudo-rs) ===
  security.sudo = {
    enable = false; # Disable traditional C-based sudo
  };
  security.sudo-rs = {
    enable = true;
    execWheelOnly = true; # Only users in 'wheel' group can execute sudo
    wheelNeedsPassword = true;
  };

  # === AppArmor (Kernel Sandboxing) ===
  # NOTE: killUnconfinedConfinables is set to false to prevent system services
  # (NetworkManager, udev, dhcpcd, dnscrypt-proxy) from being killed when their
  # AppArmor profiles are defined but not yet confined after an update/reboot.
  # This avoids unexpected USB / network failures on cold boot.
  security.apparmor = {
    enable = true;
    killUnconfinedConfinables = false;
  };

  # === Firejail (Application Sandboxing) ===
  # Allows running regular applications in highly restricted sandboxes easily
  # Example usage: `firejail firefox` or `firejail --private=~/safe_zone <app>`
  programs.firejail = {
    enable = true;
  };

  # === Application Firewall (OpenSnitch) ===
  # Interactive app-level firewall. Prompts on new outbound connections.
  services.opensnitch.enable = true;

  # === USB Protection (USBGuard) ===
  services.usbguard = {
    enable = true;
    presentDevicePolicy = "allow";
    rules = ''
      # ── Standard peripherals ──
      allow with-interface equals { 08:*:* }     # Mass Storage (USB drives, etc.)
      allow with-interface equals { 03:*:* }     # HID (Keyboards, Mice)

      # ── Phone & Mobile connectivity ──
      allow with-interface equals { 06:*:* }     # Still Image Capture (MTP / PTP mode)
      allow with-interface equals { 02:*:* }     # Communications (USB Tethering control / ECM / RNDIS)
      allow with-interface equals { 0A:*:* }     # CDC Data (USB Tethering data channel)
      allow with-interface equals { FF:*:* }     # Vendor Specific (ADB, custom phone MTP, firmware)

      # ── Bluetooth ──
      allow with-interface equals { E0:*:* }     # Wireless Controller (Bluetooth dongles)

      # ── Reject BadUSB: devices that pretend to be both Storage AND Keyboard ──
      reject with-interface all-of { 08:*:* 03:00:* }
      reject with-interface all-of { 08:*:* 03:01:* }

      # ── Catch-all: allow any other device not explicitly rejected above.
      #     Rules are top-down; first match wins, so BadUSB rejects still fire.
      allow
    '';
  };

  # === Kernel Sysctl Hardening ===
  # NOTE: rp_filter is intentionally omitted — delegated to
  # networking.firewall.checkReversePath = "loose" so that USB tethering,
  # VPN interfaces (tun2proxy, sing-box) and multi-homing work reliably.
  boot.kernel.sysctl = {
    # Ignore ICMP broadcasts (prevents smurf attacks)
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    # Restrict viewing kernel pointers (helps prevent kernel exploits)
    "kernel.kptr_restrict" = 2;
    # Restrict dmesg access to root only
    "kernel.dmesg_restrict" = 1;
    # Disable magic SysRq keys (prevents physical access attacks)
    "kernel.sysrq" = 0;

    # Block TIOCSTI keystroke injection into the controlling terminal.
    # Disabled by default since Linux 6.2, but pinned explicitly because the
    # `box` sandbox deliberately omits bwrap's --new-session: setsid() breaks
    # every interactive TUI (fish refuses to start, agent chat UIs never
    # draw). The kernel-level block replaces that protection, so a boxed
    # program still cannot push characters into the outer shell.
    "dev.tty.legacy_tiocsti" = 0;
  };

  # === Clean /tmp on boot (prevents stale secrets from persisting) ===
  boot.tmp.cleanOnBoot = true;

  # === Tooling for Manual Sandboxing ===
  environment.systemPackages = with pkgs; [
    bubblewrap # Unprivileged sandboxing tool for manual isolation
    gocryptfs # Encrypted filesystem for securing specific project folders
    opensnitch-ui # Interactive app firewall GUI
  ];
}
