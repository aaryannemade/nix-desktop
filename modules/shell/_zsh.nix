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
      cat = "bat";
      c = "clear";
      ll = "ls -la";
      btw = "echo I use nixos now, btw";
      vpn-connect = "protonvpn connect --country DE";
      vpn-disconnect = "protonvpn disconnect";
    };

    initExtra = ''
      function __zoxide_fzf() {
        local dir
        dir=$(zoxide query -l | fzf --preview 'ls -la --color=always -- {}' --height 40% --reverse)
        if [[ -n "$dir" ]]; then
          builtin cd -- "$dir"
          zle reset-prompt
        fi
      }

      zle -N __zoxide_fzf
      bindkey '^g' __zoxide_fzf
    '';
  };
}
