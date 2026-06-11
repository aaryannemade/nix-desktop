{ config, pkgs, ... }:
{
  programs.quickshell.enable = true;

  home.packages = with pkgs; [
    playerctl
    power-profiles-daemon
  ];

  xdg.configFile."quickshell" = {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-desktop/modules/window-managers/quickshell/config";
    recursive = true;
  };
}
