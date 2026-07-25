{
  config,
  ...
}:

# Host hardware/driver config only. CUDA userspace features (cuda_* unfree,
# btop/blender/obs overrides, caches, ollama-cuda) and the btop iGPU perf wrapper
# live in ./overrides.nix.
{
  # NVIDIA driver unfree allowances belong with the GPU hardware config.
  my.unfreePackages = [
    "nvidia-x11"
    "nvidia-settings"
  ];

  boot.blacklistedKernelModules = [ "nouveau" ];

  services.xserver = {
    videoDrivers = [
      "modesetting"
      "nvidia"
    ];
  };

  hardware.graphics.enable = true;

  hardware.graphics.enable32Bit = true;

  hardware.nvidia = {
    modesetting.enable = true;

    powerManagement.enable = false;
    powerManagement.finegrained = false;

    open = true;
    nvidiaSettings = true;

    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

}
