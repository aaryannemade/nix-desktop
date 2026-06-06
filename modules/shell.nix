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

  # Terminal Apps
  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      window-theme = "dark";
    };
  };
}
