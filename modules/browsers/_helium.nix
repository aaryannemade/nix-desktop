{ inputs, pkgs, ... }:

{
  home.packages = [
    inputs.helium.packages.${pkgs.system}.default
  ];
}
