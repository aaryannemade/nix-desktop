{ ... }:

{
  imports = [
    ../overrides/nvidia-cuda.nix
    ../overrides/btop-cuda.nix
    ../overrides/ollama-cuda.nix
    ../overrides/ollama-cuda-wsl.nix
  ];
}
