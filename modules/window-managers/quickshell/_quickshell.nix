{ config, pkgs, ... }:
{
  programs.quickshell.enable = true;

  # Quickshell Dependencies
  home.packages = with pkgs; [
    playerctl
    power-profiles-daemon
    # Wallpaper 
    awww
    #clipbard
    cliphist
    #Screenshot
    grim
    imagemagick
    libnotify
    slurp
  ];

  xdg.configFile."quickshell" = {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-desktop/modules/window-managers/quickshell/config";
    recursive = true;
  };
}
