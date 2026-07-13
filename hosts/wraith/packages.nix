{ pkgs, ... }:

{
  programs.coolercontrol.enable = true;

  services.hardware.openrgb = {
    enable = true;
    package = pkgs.openrgb-with-all-plugins;
    motherboard = "intel";
  };

  environment.systemPackages = with pkgs; [
    asusctl
    brightnessctl
    gamescope-wsi
    lm_sensors # Needed for CoolerControl
    liquidctl # Needed for CoolerControl
    openrgb-with-all-plugins
  ];
}
