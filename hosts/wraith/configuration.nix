{
  pkgs,
  hostname,
  ...
}:

{
  imports = [
    ../../configuration.nix # Import common config
    ./hardware-configuration.nix
    ./packages.nix # Import host specific packages
    ./graphics.nix # Import graphics/display config
    ./overrides.nix # Import CUDA/feature overrides
    ./drive-mounts.nix # Import for local drive mounts

    # Extra system apps
    ../../system/nixos/opendeck.nix
  ];

  time.timeZone = "Asia/Calcutta";

  # Wake-on-LAN (magic packet) on the wired NIC, so it can be woken from
  # suspend to SSH in. Global NM default, so it also applies to the
  # auto-created "Wired connection 1" profile. MAC: 04:d4:c4:54:87:75
  networking.networkmanager.settings.connection."ethernet.wake-on-lan" = "magic";

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
    };
    zsh.shellAliases = {
      nrs = "sudo nixos-rebuild switch --flake ~/nix-desktop#${hostname}";
    };
  };
}
