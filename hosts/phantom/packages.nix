{ pkgs, ... }:

{
    environment.systemPackages = with pkgs; [
        asusctl
        brightnessctl
    ];
}