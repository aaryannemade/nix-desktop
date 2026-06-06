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

  programs = {
    steam = {
      enable = true;
      extraCompatPackages = [
        pkgs.proton-ge-bin
      ];
      gamescopeSession.enable = true;
    };
    gamescope = {
      enable = true;
      capSysNice = true;
    }
  };

  services = {
    # Enable asus laptop control
    asusd = {
      enable = true;
    };
    # Enable Power Management
    upower = {
      enable = true;
    };
    power-profiles-daemon = {
      enable = true;
    };
  };
}
