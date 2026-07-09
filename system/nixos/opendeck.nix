{ inputs, pkgs, ... }:

{
  nixpkgs.overlays = [ inputs.opendeck-nix.overlays.default ];

  environment.systemPackages = [ pkgs.opendeck ];
  services.udev.packages = [ pkgs.opendeck ];
}
