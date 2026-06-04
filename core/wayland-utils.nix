{ pkgs, ... }:

{
    environment.systemPackages = with pkgs; [
        wl-clipboard
        wlr-randr
    ];
}