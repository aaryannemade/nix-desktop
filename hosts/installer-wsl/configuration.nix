# Generic, keyless WSL image.
#
# Mirrors the installer ISO philosophy: a minimal, secret-free WSL system that
# carries a read-only copy of this repo and seeds it into ~/nix-desktop on first
# boot. After `wsl --import`, converge to a real host with:
#   sudo nixos-rebuild switch --flake ~/nix-desktop#<host>
#
# It deliberately does NOT import the full ./system tree (which declares agenix
# secrets that require a registered/rekeyed host key) so the image boots on any
# machine with no keys present. Set up the SSH host key + secrets.nix after
# import, then converge.
#
# Build (produces a .wsl tarball, needs sudo for rootfs ownership):
#   nix run .#installer-wsl -- [out.wsl]
{
  pkgs,
  lib,
  self,
  inputs,
  ...
}:

let
  username = "aaryan";
in
{
  imports = [
    inputs.nixos-wsl.nixosModules.default
    ../../system/shared/seed-repo.nix
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  wsl = {
    enable = true;
    defaultUser = username;
    interop.includePath = true;
    startMenuLaunchers = true;
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  networking.hostName = "nixos";

  services.openssh.enable = true;

  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  users.users.${username} = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
  };

  environment.systemPackages = [ pkgs.git ];

  # Seed a writable repo copy into ~/nix-desktop on first boot so `nrs` works.
  my.seedRepo = {
    enable = true;
    source = self;
    user = username;
  };

  system.stateVersion = "25.05";
}
