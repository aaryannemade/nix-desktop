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

    powerManagement.enable = true;
    powerManagement.finegrained = false;
    # Defaults to true on 595+ open modules. Use the classic nvidia-sleep.sh
    # systemd services instead (VT switch around suspend), so mango fully
    # re-acquires and re-modesets every output on resume; with the kernel
    # notifiers a monitor intermittently stayed dark ("Failed to disable CRTC").
    powerManagement.kernelSuspendNotifier = false;

    open = true;
    nvidiaSettings = true;

    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

}
