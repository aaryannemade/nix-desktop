{ pkgs, ... }:

# Build btop with CUDA support so system/shared/system-monitoring.nix installs
# a btop that reads the NVIDIA GPU via libnvidia-ml. Global override (not just
# environment.systemPackages) so every reference to `btop` picks up the variant.
{
  nixpkgs.config.packageOverrides = pkgs: {
    btop = pkgs.btop.override { cudaSupport = true; };
  };
}
