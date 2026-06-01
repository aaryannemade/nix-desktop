{ pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    dotDir = ".config/zsh";
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
      btw = "echo I use nixos, btw";
    };
  };
}
