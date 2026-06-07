{ pkgs, ... }:

{
  ##
  programs.zed-editor = {
    enable = true;
    extensions = [ "nix" "toml" "rust" "catppuccin" ];
    userSettings = {
      theme = {
        mode = "dark";
        dark = "Catppuccin Mocha";
        light = "Catppuccin Latte";
      };
      hour_format = "hour12";
      vim_mode = true;
    };
  };
}
