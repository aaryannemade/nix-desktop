{ pkgs, inputs, ... }:

{
  home.packages = [
    inputs.filmcraft.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
