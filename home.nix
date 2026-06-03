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
{
    home.username = "aaryan";
    home.homeDirectory = "/home/aaryan";
    home.stateVersion = "25.05";

    home.activation.createPicturesDirectories = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME/Pictures/Screenshots"
    '';

    imports = [
      ./modules/zsh.nix
      ./modules/git.nix
      ./modules/bat.nix
      # ./modules/wl-clipboard.nix
      ./modules/media-players.nix
      ./modules/neovim.nix
      ./modules/mangowm.nix
      ./modules/quickshell.nix
      ./modules/bluetooth-ui.nix
      ./modules/btop.nix
      ./modules/screenshot.nix
      ./apps/ghostty.nix
      ./apps/librewolf.nix
    ];


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
