{ ... }:

# CUDA userspace support: unfree allowances for the CUDA libraries plus the
# nixos-cuda binary cache so CUDA-enabled packages don't rebuild.
#
# The NVIDIA *driver* allowances (nvidia-x11, nvidia-settings) are a host GPU
# concern and live in each host's graphics.nix (native) or system/wsl/graphics.nix
# (WSL passthrough) — NOT here. This file is purely the CUDA toolkit layer.
# Import from a host's overrides.nix whenever it uses CUDA userspace.
{
  my.unfreePackages = [
    "cuda_cudart"
    "cuda_nvcc"
    "cuda_cccl"
    "libcublas"
  ];

  nix.settings = {
    substituters = [ "https://cache.nixos-cuda.org" ];
    trusted-public-keys = [
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
    ];
  };
}
