{ ... }:

{
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };

    grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      configurationLimit = 5;
      copyKernels = false;
      useOSProber = true;
    };
  };
}
