# Replace this with the output of `nixos-generate-config --show-hardware-config`.
{modulesPath, ...}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # `boot.initrd.kernelModules` and `boot.extraModulePackages` concatenate in
  # nixpkgs, so an empty list never clears them — only add the entries this
  # machine actually needs.
  boot = {
    initrd = {
      availableKernelModules = [];
    };
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/change-me";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/change-me";
    fsType = "vfat";
    options = ["fmask=0077" "dmask=0077"];
  };

  swapDevices = [];

  # The platform is NOT set here. `lib/mkHost.nix` owns
  # `nixpkgs.hostPlatform` and takes it from the `system` argument that
  # flake.nix passes per host.
}
