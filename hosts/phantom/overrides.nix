{ ... }:

{
  imports = [
    ../overrides/nvidia-cuda.nix
    ../overrides/btop-cuda.nix
    ../overrides/btop-intel-igpu.nix
    ../overrides/ollama-cuda.nix
    ../overrides/blender-cuda.nix
    ../overrides/obs-cuda.nix
    ../overrides/steam.nix
  ];
}
