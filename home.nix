{ config, lib, pkgs, ... }:

let 
  # Import shared helper functions
  importModules = import ./helpers/importModules.nix { inherit lib; };
  createDirectories = import ./helpers/createDirectories.nix { inherit lib config; };
in
{
    home.username = "aaryan";
    home.homeDirectory = "/home/aaryan";
    home.stateVersion = "25.05";

    # Create standard home directories on activation
    home.activation.createHomeDirectories = createDirectories [
      "Desktop"
      "Documents"
      "Downloads"
      "Pictures"
      "Pictures/Screenshots"
      "Music"
      "Videos"
      "Projects"
    ];

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
