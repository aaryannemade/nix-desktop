{ inputs, config, ... }:
{
  imports = [ inputs.noctalia.homeModules.default ];

  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    settings = { # This may also be a string or path to a .toml file.
      launch_apps_as_systemd_services = true;
      theme = {
        mode = "dark";
        source = "wallpaper";
        wallpaper_scheme = "m3-rainbow";
      };
      shell = {
        ui_scale = 1.0;
        # font_family = "";
        lang = "en";
        shadow = {
          direction = "center";
          alpha = 0;
        };
        screen_corners = {
          enabled = true;
          size = 32;
        };
        panel = {
          transparency_mode = "soft";
          borders = true;
          shadow = false;
          launcher_placement = "centered";
          clipboard_placement = "centered";
          control_center_placement = "attached";
          wallpaper_placement = "attached";
          session_placement = "attached";
          open_near_click_control_center = false;
          open_near_click_launcher = false;
          open_near_click_clipboard = false;
          open_near_click_wallpaper = false;
          open_near_click_session = false;
          launcher_categories = true;
          launcher_show_icons = true;
          launcher_compact = false;
          launcher_session_search = false;
        };
      };
      wallpaper = {
        enabled = true;
        directory = "${config.home.homeDirectory}/Pictures/Wallpapers";
        transition_on_startup = false;
        transition = [ "fade" ];
        default = {
          path = "${config.home.homeDirectory}/Pictures/Wallpapers/eva.png";
        };
      };
      desktop_widgets = {
        enabled = false;  
      };
      dock = {
        enabled =false;
      };
      osd = {
        position = "center-left";
        orientation = "vertical";
      };
    };
  };
}
