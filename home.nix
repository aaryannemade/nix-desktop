{ config, pkgs, ... }:
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

    imports = [
      ./modules/zsh.nix
      ./modules/git.nix
      ./modules/bat.nix
      # ./modules/wl-clipboard.nix
      ./modules/neovim.nix
      ./modules/mangowm.nix
      ./modules/quickshell.nix
      ./modules/btop.nix
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
      #waybar
    ];
}
