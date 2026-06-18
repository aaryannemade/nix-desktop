{ config, inputs, pkgs, ... }:

{
  imports = [
    ./system
  ];

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
