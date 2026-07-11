# ============================================================
# HOST: nixos — Acer Aspire A715-42G
# ============================================================
# This file contains host-specific configuration.
# Hardware-specific settings are in hardware.nix.
{...}: {
  imports = [
    ./hardware.nix
    ../../modules/nixos
  ];

  # Bootloader (UEFI system)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Hardware-specific: Nvidia bus IDs for this machine
  # These must match the actual PCI addresses of your GPUs
  # Verify with: lspci | grep -i vga
  hardware.nvidia.prime = {
    amdgpuBusId = "PCI:4:0:0"; # AMD Lucienne (integrated)
    nvidiaBusId = "PCI:1:0:0"; # GTX 1650 (discrete)
  };
}
