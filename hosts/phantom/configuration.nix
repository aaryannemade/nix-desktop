{ config, lib, pkgs, ... }:

{
  imports = [
    ../../configuration.nix # Import common config
    ./hardware-configuration.nix  # Import hardware config
    ./packages.nix # Import host specific packages
    ./graphics.nix # Import graphcis/display config    
  ];

  networking.hostName = "phantom";

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  services = {
    # Enable asus laptop control
    asusd = {
      enable = true;
    };
  };

  # Phantom-specific overrides can go here in the future
  programs.zsh.shellAliases = {
    nrs = "sudo nixos-rebuild switch --flake ~/nix-desktop#phantom";
  };

}
