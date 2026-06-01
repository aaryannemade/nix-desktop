{ config, pkgs, ... }:
let
  dotfiles = "${config.home.homeDirectory}/nixos-dotfiles/config";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;
  configs = {
    qtile = "qtile";
    nvim = "nvim";
  };
in

{
    home.username = "aaryan";
    home.homeDirectory = "/home/aaryan";
    programs.git.enable = true;
    home.stateVersion = "25.05";

    imports = [
      ./modules/zsh.nix
      ./modules/git.nix
      ./modules/bat.nix
      ./modules/neovim.nix
      ./modules/btop.nix
      ./apps/ghostty.nix
      ./apps/librewolf.nix
    ];


    xdg.configFile = builtins.mapAttrs (name: subpath: {
      source = create_symlink "${dotfiles}/${subpath}";
      recursive = true;
    }) configs;

    # home.packages = with pkgs; [
    # ];
}
