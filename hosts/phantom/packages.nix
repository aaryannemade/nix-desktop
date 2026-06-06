{ pkgs, ... }:

{
    environment.systemPackages = with pkgs; [
        asusctl
        brightnessctl
        gamescope-wsi
    ];
}