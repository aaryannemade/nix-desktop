{ config, lib, pkgs, ... }:

let 
  # Import shared helper function
  importModules = import ./helpers/importModules.nix { inherit lib; };
in
{
    home.username = "aaryan";
    home.homeDirectory = "/home/aaryan";
    home.stateVersion = "25.05";

    home.activation.createPicturesDirectories = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME/Pictures/Screenshots"
    '';

    imports = 
      (importModules ./modules) ++
      (importModules ./apps);

    wayland.windowManager.mango.enable = true;

    services = {
      mpris-proxy = {
        enable = true;
      };
    };

    home.packages = with pkgs; [
      # Packages are now auto-imported from ./apps/ and ./modules/
      # Add any additional one-off packages here if needed
    ];
}
