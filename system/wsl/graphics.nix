{ lib, ... }:

{
  my.unfreePackages = [
    "nvidia-x11"
    "nvidia-settings"
  ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  environment.sessionVariables = {
    LD_LIBRARY_PATH = lib.mkDefault "/usr/lib/wsl/lib";
  };
}
