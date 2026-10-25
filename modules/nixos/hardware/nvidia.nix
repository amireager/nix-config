# NVIDIA HYBRID GRAPHICS — Acer Aspire A715-42G
# GPU: GTX 1650 Mobile (Turing TU117) + AMD Lucienne (Integrated)
_: {
  # The dGPU is the only device with proprietary userspace, so it is the only
  # entry needed here. The integrated AMD GPU keeps working through Mesa, which
  # nixpkgs installs as `hardware.graphics.package` and exposes to applications
  # through /run/opengl-driver. Listing "amdgpu" would only add the iGPU to
  # the initrd module list without changing which GPU drives the display.
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    # Open kernel modules are officially unstable on mobile Turing (TU117/GTX 1650).
    # Proprietary drivers (open = false) ensure reliable suspend/resume and Wayland prime offload.
    open = false;
    modesetting.enable = true;
    powerManagement = {
      enable = true;
      finegrained = true;
    };
    nvidiaSettings = false;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      amdgpuBusId = "PCI:4:0:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # nixpkgs adds the NVIDIA kernel modules to `boot.kernelModules` only when
  # `services.xserver.enable` is true. This host is Wayland-only, so without
  # this list the modules would be pulled in implicitly by udev modalias
  # matching — which works, but leaves the load order to chance.
  #
  # The list is exactly the one nixpkgs uses for the X11 case
  # ("nvidia", "nvidia_modeset", "nvidia_drm") and deliberately stops there:
  # `nvidia_uvm` must NOT be listed. It needs the GPU device to be bound
  # already, and nixpkgs therefore loads it through
  # `softdep nvidia post: nvidia-uvm` in extraModprobeConfig, right after
  # the udev rules for the nvidia module have run. Loading it eagerly from
  # boot.kernelModules loads it before the device exists.
  boot.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_drm"
  ];

  # The NVIDIA module parameters are deliberately NOT set here.
  # nixpkgs owns them and writes them to /etc/modprobe.d/nix.conf:
  #
  #   options nvidia-drm fbdev=1 modeset=1
  #   options nvidia NVreg_DynamicPowerManagement=0x02 NVreg_PreserveVideoMemoryAllocations=1
  #
  # Repeating them on the kernel command line would create a second source of
  # truth that silently drifts whenever nixpkgs changes its defaults.
}
