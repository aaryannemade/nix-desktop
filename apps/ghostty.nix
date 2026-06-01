{ pkgs, ... }:

{
  programs.ghostty = {
    enable = true;

    enableZshIntegration = true;

    settings = {
      font-size = 18;

      window-theme = "dark";
    };
  };
}
