{ pkgs, ... }:

{
  home.packages = with pkgs; [
    overskride
    bluetuith
  ];
}
