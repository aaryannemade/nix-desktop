{ config, inputs, pkgs, import-tree, ... }:

{
  imports = [
    ./system
    (import-tree ./core)
  ];

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  time.timeZone = "Asia/Calcutta";

  services = {
    ollama = {
      enable = true;
    };
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  system.stateVersion = "25.05";
}
