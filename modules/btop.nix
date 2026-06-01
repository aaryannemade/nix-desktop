{ pkgs, ... }:

{
  programs.btop = {
    enable = true;

    settings = {
      color_theme = "tokyo-night";
      update_ms = 400;
    };
  };
}
