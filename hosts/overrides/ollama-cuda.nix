{ lib, unstablePkgs, ... }:

# Upgrade Ollama to the CUDA build. The base service is enabled in
# system/shared/ai.nix with `package = lib.mkDefault unstablePkgs.ollama`;
# this overrides that default on CUDA hosts.
{
  services.ollama.package = lib.mkForce unstablePkgs.ollama-cuda;
}
