{ config, pkgs, ... }:

{
  # Shell Apps
  home.packages = with pkgs; [
    bat
    zoxide
  ];

  #Shell Config
  programs.zsh = {
    enable = true;
    dotDir = "${config.home.homeDirectory}/.config/zsh";
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "npm"
        "node"
      ];
      theme = "robbyrussell";
    };

    shellAliases = {
      cat = "bat";
      c = "clear";
      ll = "ls -la";
      btw = "echo I use nixos now, btw";
      vpn-connect = "protonvpn connect --country DE";
      vpn-disconnect = "protonvpn disconnect";
    };
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.yazi = {
    enable = true;
    settings = {
      yazi = {
        ratio = [
          1
          4
          3
        ];
        sort_by = "natural";
        sort_sensitive = true;
        sort_reverse = false;
        sort_dir_first = true;
        linemode = "none";
        show_hidden = true;
        show_symlink = true;
      };

      preview = {
        image_filter = "lanczos3";
        image_quality = 90;
        tab_size = 1;
        max_width = 600;
        max_height = 900;
        cache_dir = "";
        ueberzug_scale = 1;
        ueberzug_offset = [
          0
          0
          0
          0
        ];
      };

      tasks = {
        micro_workers = 5;
        macro_workers = 10;
        bizarre_retry = 5;
      };
    };
  };

  # Terminal Apps
  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      window-theme = "dark";
    };
  };
}
