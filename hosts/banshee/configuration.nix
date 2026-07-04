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
    ./graphics.nix # Import graphics/CUDA config
  ];

  # NOTE: no hardware-configuration.nix here. Under WSL the filesystem layout
  # and boot are provided by the NixOS-WSL module (pulled in per-platform in
  # hosts/default.nix), so there is nothing for nixos-generate-config to scan.

  time.timeZone = "Asia/Calcutta";

  programs = {
    zsh.shellAliases = {
      nrs = "sudo nixos-rebuild switch --flake ~/nix-desktop#${hostname}";
    };
  };
}
