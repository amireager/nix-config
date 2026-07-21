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
    ../../modules/nixos/network.nix
    ../../modules/nixos/security.nix
    ../../modules/nixos/desktop.nix
  ];

  # Bootloader (UEFI system)
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;
}
