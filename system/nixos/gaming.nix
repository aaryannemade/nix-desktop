{ pkgs, ... }:

{
  my.unfreePackages = [
    "steam"
    "steam-unwrapped"
  ];

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
  };
}
