# ============================================================
# NVIDIA HYBRID GRAPHICS — Acer Aspire A715-42G
# GPU: GTX 1650 Mobile (Turing) + AMD Lucienne (Integrated)
# ============================================================
{...}: {
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = true;
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
