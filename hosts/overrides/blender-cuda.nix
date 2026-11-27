{ inputs, ... }:

# CUDA-accelerated Blender from the blender-cuda flake input. Pulls in the
# maintainer's cachix so the CUDA Blender build is fetched rather than compiled
# locally. Import from hosts that run Blender (desktops); WSL hosts skip this.
{
  # Allow unfree even when blender is FOSS because of cuda integration, only needed when using blender cuda
  my.unfreePackages = [ "blender" ];

  nixpkgs.config.packageOverrides = pkgs: {
    blender = inputs.blender-cuda.packages.${pkgs.stdenv.hostPlatform.system}.blender-with-cuda;
  };

  nix.settings = {
    substituters = [ "https://adithyagenie.cachix.org" ];
    trusted-public-keys = [
      "adithyagenie.cachix.org-1:h6BSMboeVfxyrULWuRQqAyweo4AJRATekb88xotfQwc="
    ];
  };
}
