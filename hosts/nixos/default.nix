# ============================================================
# HOST: nixos — Acer Aspire A715-42G
# ============================================================
{...}: {
  imports = [
    # ========================================================
    # 1. Host-Specific & Hardware Layer (Unique to this machine)
    # ========================================================
    ./hardware.nix
    ../../modules/nixos/hardware/laptop.nix
    ../../modules/nixos/hardware/nvidia.nix
    ../../modules/nixos/keyd.nix

    # ========================================================
    # 2. General System Profile Layer (Shared / Modular)
    # ========================================================
    ../../modules/nixos/core.nix
    ../../modules/nixos/performance.nix
    ../../modules/nixos/network.nix
    ../../modules/nixos/security.nix
    ../../modules/nixos/virtualisation.nix
    ../../modules/nixos/desktop.nix
  ];

  # Bootloader (UEFI system)
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 10;
    };
    efi.canTouchEfiVariables = true;
    timeout = 1;
  };

  # Compatibility baseline of the original installation; never bump merely to
  # follow the current release.
  system.stateVersion = "26.05";
}
