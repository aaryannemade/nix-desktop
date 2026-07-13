{ pkgs, ... }:

{
  services.hardware.openrgb = {
    enable = true;
    package = pkgs.openrgb-with-all-plugins;
    motherboard = "intel";
  };

  hardware.i2c.enable = true;

  boot.kernelModules = [ "i2c-dev" ];

  environment.systemPackages = with pkgs; [
    openrgb-with-all-plugins
  ];
}
