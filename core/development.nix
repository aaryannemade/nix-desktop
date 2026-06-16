{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    git
    neovim
    docker-compose
    blender
  ];
}
