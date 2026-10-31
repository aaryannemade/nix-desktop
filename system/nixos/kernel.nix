{ pkgs, inputs, ... }:

# CachyOS kernel (latest), from the nix-cachyos-kernel flake input.
#
# The `pinned` overlay exposes pkgs.cachyosKernels built from that flake's own
# nixpkgs pin (nixos-unstable-small), matching what its Hydra pushed to the
# lantian cache. Kernel modules (incl. the NVIDIA driver selected in each
# host's graphics.nix via config.boot.kernelPackages.nvidiaPackages) therefore
# also come from that pin, not from our nixos-26.05 nixpkgs.
#
# x86_64-v3 (AVX2) variant: both NixOS hosts support it (wraith: i9-9900K,
# phantom: 12th gen i7). Don't use it on a pre-Haswell CPU, it won't boot.
{
  nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.pinned ];

  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-x86_64-v3;

  # Binary cache for the CachyOS kernels. Set here as well as in flake.nix's
  # nixConfig, which only applies to interactive nix commands that accept it.
  nix.settings = {
    substituters = [ "https://cache.lantian.pub/lantian" ];
    trusted-public-keys = [
      "lantian:WVGO7vsRMSEN+h7Lp7kv6SAmrkEXgUGbbXm7jMDjBuQ="
    ];
  };
}
