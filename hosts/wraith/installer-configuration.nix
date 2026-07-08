# Minimal installer config for wraith. NOT imported by the flake.
# Copy to /mnt/etc/nixos/configuration.nix during the manual install
# (alongside the generated hardware-configuration.nix), then follow
# "WRAITH HOST SETUP" in the README.
{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Same GRUB-EFI layout as system/nixos/bootloader.nix so the flake
  # switch takes over cleanly. /boot is the existing 200 MB Windows ESP
  # (reused, never formatted); kernels stay in /nix/store on the LVM
  # root. useOSProber here so the Windows entry shows up from the first
  # boot, matching the repo config.
  boot.loader = {
    efi.canTouchEfiVariables = true;
    grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      useOSProber = true;
    };
  };

  networking.hostName = "wraith";
  networking.networkmanager.enable = true;

  time.timeZone = "Asia/Calcutta";

  # Required so `nixos-rebuild switch --flake` works after the rsync.
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Password set via `passwd` survives the flake switch (mutableUsers
  # defaults to true and the repo's users.nix sets no hashedPassword).
  users.users.aaryan = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };

  # Generates /etc/ssh/ssh_host_ed25519_key on first boot (needed by
  # agenix) and allows the repo rsync from phantom.
  services.openssh.enable = true;

  environment.systemPackages = with pkgs; [
    git
    vim
    rsync
  ];

  system.stateVersion = "26.05";
}
