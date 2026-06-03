{ config, inputs, pkgs, lib, ...}:

{
  home.packages = with pkgs; [
    #tools required for Telescope
    ripgrep
    fd
    fzf

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
  #programs.neovim = {
  #  enable = true;
  #  viAlias = true;
  #  vimAlias = true;
  #  withRuby = false;
  #  withPython3 = false;
  #};
}
