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
    xdg = {
      userDirs = {
        enable = true;
        createDirectories = true;
        desktop = "${config.home.homeDirectory}/desktop";
        documents = "${config.home.homeDirectory}/documents";
        download = "${config.home.homeDirectory}/downloads";
        pictures = "${config.home.homeDirectory}/pictures";
        music = "${config.home.homeDirectory}/music";
        videos = "${config.home.homeDirectory}/videos";
        projects = "${config.home.homeDirectory}/projects";
        extraConfig = {
          screenshots = "${config.home.homeDirectory}/pictures/screenshots";
          screenrecordings = "${config.home.homeDirectory}/videos/screenrecordings";
          trash = "${config.home.homeDirectory}/trash";
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
