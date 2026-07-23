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
  # Extremely powerful for isolating processes
  security.apparmor = {
    enable = true;
    killUnconfinedConfinables = true;
  };

  # === Firejail (Application Sandboxing) ===
  # Allows running regular applications in highly restricted sandboxes easily
  # Example usage: `firejail firefox` or `firejail --private=~/safe_zone <app>`
  programs.firejail = {
    enable = true;
  };

  # === USB Protection (USBGuard) ===
  # Prevents BadUSB attacks by implicitly denying new devices while screen is locked.
  # We use 'allow' policy for present devices so you don't lock yourself out on boot.
  services.usbguard = {
    enable = true;
    # Allow all devices plugged in during boot.
    presentDevicePolicy = "allow";
    rules = ''
      # Explicitly allow standard USB Mass Storage, Keyboards, and Mice
      allow with-interface equals { 08:*:* }
      allow with-interface equals { 03:*:* }
      # Reject highly suspicious dual-interface devices (e.g. Storage that is also a Keyboard)
      reject with-interface all-of { 08:*:* 03:00:* }
      reject with-interface all-of { 08:*:* 03:01:* }
    '';
  };

  # === Kernel Sysctl Hardening ===
  boot.kernel.sysctl = {
    # Prevent IP spoofing
    "net.ipv4.conf.all.rp_filter" = 1;
    # Ignore ICMP broadcasts (prevents smurf attacks)
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    # Restrict viewing kernel pointers (helps prevent kernel exploits)
    "kernel.kptr_restrict" = 2;
    # Restrict dmesg access to root only
    "kernel.dmesg_restrict" = 1;
    # Disable magic SysRq keys (prevents physical access attacks)
    "kernel.sysrq" = 0;
  };

  # === Clean /tmp on boot (prevents stale secrets from persisting) ===
  boot.tmp.cleanOnBoot = true;

  # === Tooling for Manual Sandboxing ===
  environment.systemPackages = with pkgs; [
    bubblewrap # Unprivileged sandboxing tool for manual isolation
    gocryptfs # Encrypted filesystem for securing specific project folders
  ];
}
