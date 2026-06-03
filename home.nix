{ config, lib, pkgs, ... }:
# let
#   dotfiles = "${config.home.homeDirectory}/nixos-dotfiles/config";
#   create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;
#   configs = {
#     #mango = "mango";
#     #quickshell = "quickshell";
#     #nvim = "nvim";
#   };
# in
let 
  # Import function for all module and app .nix files
  importModules = dir:
    let 
      inherit (lib) hasSuffix;
      inherit (builtins) readDir attrNames filter map;
    in
      dir
      |> readDir
      |> attrNames
      |> filter (name: 
           hasSuffix ".nix" name &&        # Only .nix files
           name != "default.nix"           # Exclude default.nix
         )
      |> map (name: dir + "/${name}");
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


#     xdg.configFile = builtins.mapAttrs (name: subpath: {
#       source = create_symlink "${dotfiles}/${subpath}";
#       recursive = true;
#     }) configs;

    wayland.windowManager.mango.enable = true;

    services = {
      mpris-proxy = {
        enable = true;
      };
    };

    home.packages = with pkgs; [
      #quickshell
      #overskride
      #waybar
    ];
}
