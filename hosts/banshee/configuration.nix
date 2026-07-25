{
  config,
  lib,
  pkgs,
  hostname,
  ...
}:

{
  imports = [
    ../../configuration.nix # Import common config
    ./overrides.nix # Import CUDA/feature overrides
  ];

  time.timeZone = "Asia/Calcutta";

  programs = {
    zsh.shellAliases = {
      nrs = "sudo nixos-rebuild switch --flake ~/nix-desktop#${hostname}";
    };
  };
}
