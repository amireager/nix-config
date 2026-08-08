# ============================================================
# NVIDIA HYBRID GRAPHICS — Acer Aspire A715-42G
# GPU: GTX 1650 Mobile (Turing TU117) + AMD Lucienne (Integrated)
# ============================================================
_: {
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

  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia.NVreg_DynamicPowerManagement=0x02"
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
  ];
}
