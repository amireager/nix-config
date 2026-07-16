# Copy this directory to hosts/<hostname>/ and customize.
{...}: {
  imports = [
    ./hardware.nix
    ../../modules/nixos/core.nix
    ../../modules/nixos/network.nix
    ../../modules/nixos/security.nix
    # ../../modules/nixos/desktop.nix
    # ../../modules/nixos/laptop.nix
    # ../../modules/nixos/nvidia.nix
  ];

  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;
}
