# Thin custom NixOS installer ISO.
#
# A minimal (no desktop) live image with the `nix-desktop-install` helper. Boot
# it, mount the target under /mnt (ESP at /mnt/boot), then run
# `sudo nix-desktop-install <hostname>` to install a minimal bootable system and
# clone the embedded release repository into the installed ~/nix-desktop.
# Converge to the real host after reboot via `nrs`.
#
# Build: nix build .#installer-iso  ->  result/iso/nix-desktop-installer.iso
{
  modulesPath,
  pkgs,
  lib,
  repoBundle,
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

  # Release/local app builds provide a full-history bundle for an offline,
  # exact-revision checkout. Plain low-level builds omit it and the helper
  # falls back to the public remote.
  environment.etc = lib.mkIf (repoBundle != null) {
    "nix-desktop.bundle".source = repoBundle;
  };

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
