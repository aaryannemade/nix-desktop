{ pkgs, ... }:

{
  programs.ghostty = {
    enable = true;

    enableZshIntegration = true;

    settings = {


      window-theme = "dark";
    };
  };
}
