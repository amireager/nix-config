# ============================================================
# HOST: nixos — Acer Aspire A715-42G
# ============================================================
{...}: {
  imports = [
    ./hardware.nix
    ../../modules/nixos/core.nix
    ../../modules/nixos/network.nix
    ../../modules/nixos/security.nix
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/laptop.nix
    ../../modules/nixos/nvidia.nix
  ];

  # Bootloader (UEFI system)
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;
}
