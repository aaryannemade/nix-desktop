{
  inputs,
  config,
  osConfig,
  pkgs,
  ...
}:
let
  idleTimeouts =
    if osConfig.networking.hostName == "phantom" then
      {
        lock = 300;
        screenOff = 330;
        suspend = 900;
      } # 5m / 5.5m / 15m
    else
      {
        lock = 600;
        screenOff = 660;
        suspend = 1800;
      }; # 10m / 11m / 30m (wraith)

  communityPlugins = pkgs.applyPatches {
    name = "noctalia-community-plugins";
    src = pkgs.fetchFromGitHub {
      owner = "noctalia-dev";
      repo = "community-plugins";
      rev = "b195cdfc9a2e91febdcf78516f96ed17e6bd5316"; # 2026-09-25
      hash = "sha256-2BhBbL6Y/k8pmU/OxMcagTIe8guQ/fqfBgPz0F3zTXo=";
    };
    patches = [
      # Upstream widget shows the focused monitor's layout on every bar; show
      # the layout of the monitor each bar is on instead.
      ./_noctalia-patches/mango_layouts-per-monitor.patch
    ];
  };
in
{
  imports = [ inputs.noctalia.homeModules.default ];

  # mpris-proxy needed for proper media player widget
  services = {
    mpris-proxy = {
      enable = true;
    };
  };

  home.packages = with pkgs; [
    satty
    jq # mango_layouts plugin pipes `mmsg get` through jq
  ];

  # Community noctalia plugins, pinned. noctalia always scans
  # $XDG_DATA_HOME/noctalia/plugins; each plugin still has to be listed in
  # settings.plugins.enabled below. To update: bump rev, set hash = "" and
  # rebuild to get the new hash.
  xdg.dataFile = {
    "noctalia/plugins/mango_layouts".source = "${communityPlugins}/mango_layouts";
    "noctalia/plugins/keybind-cheatsheet".source = "${communityPlugins}/keybind-cheatsheet";
  };

  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    settings = {
      # This may also be a string or path to a .toml file.
      launch_apps_as_systemd_services = true;
      theme = {
        mode = "dark";
        source = "wallpaper";
        wallpaper_scheme = "m3-rainbow";
        # Render the generated theme into these apps' config dirs. The nix
        # configs already reference the theme (btop color_theme, ghostty theme,
        # mango source=) since noctalia can't edit the read-only store configs.
        templates = {
          enable_builtin_templates = true;
          builtin_ids = [
            "btop"
            "ghostty"
            "mango"
          ];
        };
      };
      idle = {
        pre_action_fade_seconds = 0; # no fade
        behavior = {
          lock = {
            timeout = idleTimeouts.lock;
            action = "lock";
            enabled = true;
          };
          # Not action = "screen_off": on mango that runs disable_monitor, which
          # removes the outputs entirely -- the lock screen loses its surfaces
          # (so lock-before-suspend never completes) and mango crashes when they
          # come back. wlopm uses wlr-output-power-management, which only blanks.
          dpms = {
            timeout = idleTimeouts.screenOff;
            action = "command";
            command = "${pkgs.wlopm}/bin/wlopm --off '*'";
            resume_command = "${pkgs.wlopm}/bin/wlopm --on '*'";
            enabled = true;
          };
          suspend = {
            timeout = idleTimeouts.suspend;
            action = "suspend";
            enabled = true;
          };
        };
      };
      shell = {
        ui_scale = 1.0;
        time_format = "{:%-I:%M %p}";
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
        screenshot = {
          save_to_file = false;
          directory = "${config.home.homeDirectory}/Pictures/screenshots";
          filename_pattern = "screenshot_%Y%m%d_%H%M%S";
          copy_to_clipboard = true;
          freeze_screen = true;
          confirm_region = true;
          pipe_to_command = true;
          pipe_command = "satty -f -";
        };
        panel = {
          transparency_mode = "soft";
          borders = true;
          shadow = false;
          launcher_placement = "centered";
          clipboard_placement = "centered";
          control_center_placement = "attached";
          wallpaper_placement = "attached";
          session_placement = "centered";
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
      plugins = {
        enabled = [
          "ezequiel/mango_layouts"
          "kenn/keybind-cheatsheet"
        ];
      };
      desktop_widgets = {
        enabled = false;
      };
      dock = {
        enabled = false;
      };
      osd = {
        position = "center-left";
        orientation = "vertical";
      };
      bar = {
        order = [
          "main"
          "second"
        ];

        main = {
          position = "top";
          enabled = false;
          auto_hide = false;
          reserve_space = true;
          layer = "top";

          thickness = 40;
          background_opacity = 1.2;
          border = "primary";
          border_width = 2;
          shadow = false;
          contact_shadow = false;
          panel_overlap = 2;
          radius = 8;
          margin_ends = 8;
          margin_edge = 8;
          padding = 10;
          widget_spacing = 12;
          scale = 1.0;
          font_weight = "regular";

          capsule = false;

          start = [
            "control-center"
            "workspaces"
            "mango-layout"
          ];
          center = [
            "clock"
          ];
          end = [
            # "media"
            "tray"
            # "notifications"
            "clipboard"
            "network"
            # "bluetooth"
            # "volume"
            # "brightness"
            "battery"
            "session"
          ];

          monitor = {
            laptop = {
              match = "0x0A07";
              enabled = true;
            };
            gigabyte = {
              match = "M27Q";
              enabled = true;
            };
          };
        };

        second = {
          position = "top";
          enabled = false;
          auto_hide = false;
          reserve_space = true;
          layer = "top";

          thickness = 40;
          background_opacity = 1.2;
          border = "primary";
          border_width = 2;
          shadow = false;
          contact_shadow = false;
          panel_overlap = 2;
          radius = 8;
          margin_ends = 8;
          margin_edge = 8;
          padding = 10;
          widget_spacing = 12;
          scale = 1.0;
          font_weight = "regular";

          capsule = false;

          start = [
            "mango-layout"
          ];
          center = [
            "workspaces"
          ];
          end = [
            # "media"
            # "tray"
            # "notifications"
            # "clipboard"
            # "network"
            # "bluetooth"
            # "volume"
            # "brightness"
            # "battery"
            # "session"
          ];

          monitor = {
            mini = {
              match = "J560T09";
              enabled = true;
            };
          };
        };
      };
      widget = {
        clock = {
          format = "{:%-I:%M %p}";
        };
        control-center = {
          glyph = "ghost-3-filled";
        };
        # Named instance of the mango_layouts plugin widget; referenced by name
        # in the bar lists above.
        mango-layout = {
          type = "ezequiel/mango_layouts:btn";
          show_text = true;
        };
      };
    };
  };
}
