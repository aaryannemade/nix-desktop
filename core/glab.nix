{ pkgs, ... }:

{ 
    environment.systemPackages = with pkgs; [
        glab
    ];
}