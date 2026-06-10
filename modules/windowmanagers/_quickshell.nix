{ pkgs, inputs, ... }:

{
  programs.quickshell.enable = true;

  home.packages = with pkgs; [
    playerctl
    power-profiles-daemon
  ];

  xdg.configFile."quickshell" = {
    source = inputs.quickshell-config;
    recursive = true;
  };
}
