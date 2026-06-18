{ config, inputs, pkgs, import-tree, ... }:

{
  imports = [
    ./system
    (import-tree ./core)
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
