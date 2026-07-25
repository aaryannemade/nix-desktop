{ pkgs, ... }:

{
  # CoolerControl: fan/temp control. Needs I2C exposed plus the nct6775 Nuvoton
  # super-I/O driver and i2c-dev interface so it can read the motherboard sensors.
  # lm_sensors + liquidctl (below) are its userspace backends.
  programs.coolercontrol.enable = true;
  hardware.i2c.enable = true;
  boot.kernelModules = [
    "i2c-dev"
    "nct6775"
  ];

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
