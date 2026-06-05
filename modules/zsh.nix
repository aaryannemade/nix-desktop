{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    bat
  ];

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
      c = "clear";
      ll = "ls -la";
      btw = "echo I use nixos now, btw";
      vpn-connect = "protonvpn connect --country DE";
      vpn-disconnect = "protonvpn disconnect";
    };
  };
}
