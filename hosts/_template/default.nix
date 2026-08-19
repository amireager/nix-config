# Copy this directory to hosts/<hostname>/ and customize.
{...}: {
  imports = [
    ./hardware.nix
    ../../modules/nixos/core.nix
    ../../modules/nixos/network.nix
    ../../modules/nixos/security.nix
    # ../../modules/nixos/desktop.nix
    # ../../modules/nixos/hardware/laptop.nix
    # ../../modules/nixos/hardware/nvidia.nix
  ];

  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;
}
