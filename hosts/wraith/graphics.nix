{
  config,
  inputs,
  lib,
  pkgs,
  unstablePkgs,
  ...
}:

{
  boot.blacklistedKernelModules = [ "nouveau" ];

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "nvidia-x11"
      "nvidia-settings"
      "cuda_cudart"
      "cuda_nvcc"
      "cuda_cccl"
      "libcublas"
      "steam"
      "steam-unwrapped"
      "blender"
      "claude-code"
    ];

  # Override btop globally so core/system-monitoring.nix installs the CUDA version.
  nixpkgs.config.packageOverrides = pkgs: {
    btop = pkgs.btop.override { cudaSupport = true; };
    blender = inputs.blender-cuda.packages.${pkgs.system}.blender-with-cuda;
    obs-studio = pkgs.obs-studio.override { cudaSupport = true; };
  };

  # Enable Cuda Cache
  nix.settings = {
    substituters = [
      "https://cache.nixos-cuda.org"
      "https://adithyagenie.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
      "adithyagenie.cachix.org-1:h6BSMboeVfxyrULWuRQqAyweo4AJRATekb88xotfQwc="
    ];
  };

  # Security wrapper so btop can read the Intel iGPU performance counters.
  security.wrappers.btop = {
    owner = "root";
    group = "root";
    capabilities = "cap_perfmon+ep cap_dac_read_search+ep";
    source = "${pkgs.btop}/bin/btop";
  };

  services.xserver = {
    videoDrivers = [
      "modesetting"
      "nvidia"
    ];
  };

  # Enable Cuda for Ollama
  services.ollama.package = unstablePkgs.ollama-cuda;

  hardware.graphics.enable = true;

  hardware.graphics.enable32Bit = true;

  hardware.nvidia = {
    modesetting.enable = true;

    powerManagement.enable = false;
    powerManagement.finegrained = false;

    open = true;
    nvidiaSettings = true;

    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # PRIME offload is configured centrally in system/nixos/graphics-offload.nix,
    # enabled per-host via its offloadHosts map. wraith is a desktop: everything
    # runs on the dGPU, so it is intentionally not in that map.
  };

}
