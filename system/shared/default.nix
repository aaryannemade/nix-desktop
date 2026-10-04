{ ... }:

{
  imports = [
    ./garbage-collection.nix
    ./fonts.nix
    ./ssh.nix
    ./sudo.nix
    ./shell.nix
    ./system-monitoring.nix
    ./development.nix
    ./network.nix
    ./secrets.nix
    ./ai.nix
    ./unfree.nix
    ./seed-repo.nix
  ];
}
