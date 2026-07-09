{...}: {
  imports = [
    ./hardware.nix
    ../../modules/nixos
  ];

  # Bootloader (host-specific: must know if UEFI or BIOS)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Hardware-specific: Nvidia bus IDs for this machine
  hardware.nvidia.prime = {
    amdgpuBusId = "PCI:4:0:0";
    nvidiaBusId = "PCI:1:0:0";
  };
}
