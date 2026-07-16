{...}: {
  # ============================================================
  # SECURITY — Firewall & sudo baseline
  # ============================================================

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [];
    allowedUDPPorts = [];
  };

  security.sudo.wheelNeedsPassword = true;
}
