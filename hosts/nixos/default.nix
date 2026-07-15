# ============================================================
# HOST: nixos — Acer Aspire A715-42G
# ============================================================
# This file contains host-specific configuration.
# Hardware-specific settings are in hardware.nix.
# GPU configuration is in modules/nixos/hardware/nvidia.nix
{...}: {
  imports = [
    ./hardware.nix
    ../../modules/nixos
  ];

  # Bootloader (UEFI system)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
