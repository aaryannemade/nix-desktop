{ pkgs, ... }:

{
  home.packages = with pkgs; [
    grim
    imagemagick
    libnotify
    slurp
  ];
}
