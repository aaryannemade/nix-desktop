{ config, lib, pkgs, ... }:

{
  imports = [
    ../../configuration.nix          # Import common config
    ./hardware-configuration.nix      # Import hardware config
  ];

  # Phantom-specific overrides can go here in the future
}
