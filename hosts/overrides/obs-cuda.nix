{ pkgs, ... }:

# Build OBS Studio with CUDA support (NVENC / CUDA-accelerated filters). Global
# override so every reference to `obs-studio` picks up the variant. Import from
# hosts that run OBS; independent of the Blender override.
{
  nixpkgs.config.packageOverrides = pkgs: {
    obs-studio = pkgs.obs-studio.override { cudaSupport = true; };
  };
}
