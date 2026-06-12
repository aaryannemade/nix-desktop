{ inputs, ... }:
{
  imports = [ inputs.noctalia.homeModules.default ];

  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    settings = { # This may also be a string or path to a .toml file.
      launch_apps_as_systemd_services = true;
      theme = {
        mode = "dark";
        source = "builtin";
        builtin = "Catppuccin";
      };

      wallpaper = {
        enabled = true;
        default.path = "~/Pictures/Wallpapers/eva.png";
      };
    };
  };
}
