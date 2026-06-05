{ pkgs, ... }:

{
    environment.systemPackages = with pkgs; [
        wget
        curl
        proton-vpn-cli
    ];
}
