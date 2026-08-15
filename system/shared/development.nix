{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    git
    neovim
    podman-compose
    podman-tui
  ];
}
