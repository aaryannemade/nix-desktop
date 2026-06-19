{
  config,
  lib,
  pkgs,
  ...
}:

{
  # WSL host with Intel iGPU + NVIDIA dGPU. The actual GPU passthrough (driver
  # libs at /usr/lib/wsl/lib, /dev/dxg) and the userspace loaders live in the
  # shared system/wsl/graphics.nix. This file only carries the host's CUDA
  # package overrides + unfree allowances, mirroring the phantom split.
  #
  # Deliberately absent vs phantom (none apply under WSL):
  #   - boot.blacklistedKernelModules "nouveau" (no nvidia kernel module)
  #   - services.xserver.videoDrivers       (no X server)
  #   - hardware.nvidia / PRIME offload      (no kernel-mode driver)
  #   - btop perfmon security wrapper        (no iGPU perf counters in WSL)

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "nvidia-x11"
      "nvidia-settings"
      "cuda_cudart"
      "cuda_nvcc"
      "cuda_cccl"
      "libcublas"
      "claude-code"
    ];

  # Override btop globally so core/system-monitoring.nix installs the CUDA
  # version (reads the NVIDIA dGPU via the WSL-passthrough libnvidia-ml).
  nixpkgs.config.packageOverrides = pkgs: {
    btop = pkgs.btop.override { cudaSupport = true; };
  };

  # Enable Cuda Cache
  nix.settings = {
    substituters = [
      "https://cache.nixos-cuda.org"
    ];
    trusted-public-keys = [
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
    ];
  };

  # Enable Cuda for Ollama (uses the WSL-passthrough NVIDIA driver).
  services.ollama.package = pkgs.ollama-cuda;
}
