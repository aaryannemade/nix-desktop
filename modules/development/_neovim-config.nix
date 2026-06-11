{ config, inputs, pkgs, ... }:

{
  home.packages = with pkgs; [
    #tools required for Telescope
    ripgrep
    fd

    #tools needed for lazyvim
    tree-sitter
    gcc
    luarocks
    lazygit
    trash-cli
    glib

    #language Servers
    lua-language-server
    nil # nix language server
    nixpkgs-fmt #nix formatter

    #needed for lazy.nvim
    nodejs
  ];

  programs.neovim.enable = true;

  xdg.configFile."nvim" = {
  	source = inputs.nvim-config;
    recursive = true;
  };
}
