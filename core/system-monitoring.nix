{ pkgs, ... }:

{
    environment.systemPackages = with pkgs; [
        btop
        ncdu
        speedtest-cli
    ];
}