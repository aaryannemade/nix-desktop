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
    # ./hardware-configuration.nix # TODO: generate with `nixos-generate-config` and uncomment
    ./packages.nix # Import host specific packages
    ./graphics.nix # Import graphics/display config
  ];

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  time.timeZone = "Asia/Calcutta";

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
      # capSysNice = true;
    };
    zsh.shellAliases = {
      nrs = "sudo nixos-rebuild switch --flake ~/nix-desktop#${hostname}";
    };
  };
}
