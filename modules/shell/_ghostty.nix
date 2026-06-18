{ lib, platform, ... }:

{
  programs.ghostty = {
    enable = true;

    package = lib.mkIf (platform != "nixos") null;

    enableZshIntegration = true;
    settings = {
      window-theme = "dark";
      theme = if (platform == "nixos") then "noctalia" else "catppuccin-macchiato";
    };
  };
}
