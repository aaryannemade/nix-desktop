# Thin custom NixOS installer ISO.
#
# A minimal (no desktop) live image that carries a read-only copy of this repo
# at /etc/nix-desktop plus the `nix-desktop-install` helper. Boot it, mount the
# target under /mnt (ESP at /mnt/boot), then run `sudo nix-desktop-install
# <hostname>` to install a minimal bootable system and drop the repo into the
# installed ~/nix-desktop. Converge to the real host after reboot via `nrs`.
#
# Build: nix build .#installer-iso  ->  result/iso/nix-desktop-installer.iso
{
  modulesPath,
  pkgs,
  lib,
  self,
  ...
}:

let
  nixDesktopInstall = import ./deploy.nix { inherit pkgs; };
in
{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Read-only copy of the whole flake, available in the live env at
  # /etc/nix-desktop. The install helper copies this into the target's home.
  environment.etc."nix-desktop".source = self;

  environment.systemPackages = [
    pkgs.git
    nixDesktopInstall
  ];

  # zsh login shell in the live environment.
  programs.zsh.enable = true;
  users.users.root.shell = pkgs.zsh;

  image.fileName = "nix-desktop-installer.iso";

  system.stateVersion = "25.05";
}
