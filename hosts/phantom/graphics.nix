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

    open = true;
    nvidiaSettings = true;

    # Latest stable (production) branch from the kernel package set, i.e. the
    # nix-cachyos-kernel flake's nixpkgs pin (see system/nixos/kernel.nix), so
    # the version moves with that input. Falls back to `latest` if that package
    # set ever stops providing `stable`.
    package =
      let
        nvidiaPackages = config.boot.kernelPackages.nvidiaPackages;
      in
      nvidiaPackages.stable or nvidiaPackages.latest;

    # PRIME offload is configured centrally in system/nixos/graphics-offload.nix,
    # enabled per-host via its offloadHosts map.
  };

}
