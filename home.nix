{ config, lib, pkgs, username, ... }:

let 
  # Import shared helper functions
  importModules = import ./helpers/importModules.nix { inherit lib; };
in
{
    home.username = username;
    home.homeDirectory = "/home/${username}";
    home.stateVersion = "25.05";

    # Create standard home directories on activation
    xdg = {
      userDirs = {
        enable = true;
        createDirectories = true;
        extraConfig = {
          screenshots = "${config.home.homeDirectory}/Pictures/screenshots";
          screenrecordings = "${config.home.homeDirectory}/Videos/screenrecordings";
          trash = "${config.home.homeDirectory}/Trash";
        };
      };
    };

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
