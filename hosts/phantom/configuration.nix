{ config, lib, pkgs, ... }:

{
  imports = [
    ../../configuration.nix # Import common config
    ./hardware-configuration.nix  # Import hardware config
    ./packages.nix # Import host specific packages
    ./graphics.nix # Import graphcis/display config    
  ];

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  services = {
    # Enable asus laptop control
    asusd = {
      enable = true;
    };
  };
}
