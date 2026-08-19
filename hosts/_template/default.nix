# Copy this directory to hosts/<hostname>/ and customize.
{...}: {
  imports = [
    ./hardware.nix
    ../../modules/nixos/core.nix
    ../../modules/nixos/network.nix
    ../../modules/nixos/security.nix
    # ../../modules/nixos/performance.nix
    # ../../modules/nixos/virtualisation.nix
    # ../../modules/nixos/desktop.nix
    # ../../modules/nixos/hardware/laptop.nix
    # ../../modules/nixos/hardware/nvidia.nix
  ];

  # Bootloader policy belongs to the host.
  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;

  # Set this to the NixOS release used for the original installation, then keep
  # it stable across upgrades.
  # system.stateVersion = "YY.MM";
}
