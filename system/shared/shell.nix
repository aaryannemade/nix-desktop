{ pkgs, ... }:

{
  # zsh, enabled on all platforms (NixOS, WSL, nix-darwin all support these).
  environment.shells = with pkgs; [ zsh ];
  programs.zsh.enable = true;
}
