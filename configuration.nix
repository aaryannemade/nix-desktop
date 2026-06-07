{
  config,
  inputs,
  pkgs,
  mangowm,
  import-tree,
  username,
  hostname,
  ...
}:

{
  imports = [
    mangowm.nixosModules.mango
    (import-tree ./core)
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 5;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = hostname;
  networking.networkmanager.enable = true;

  time.timeZone = "Asia/Calcutta";

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    autoRepeatDelay = 200;
    autoRepeatInterval = 35;
  };

  services.displayManager.ly.enable = true;

  programs.mango.enable = true;

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    packages = with pkgs; [
      tree
    ];
    shell = pkgs.zsh;
  };

  environment.shells = with pkgs; [ zsh ];
  programs.zsh = {
    enable = true;
    shellAliases = {
      nrs = "sudo nixos-rebuild switch --flake ~/nix-desktop#${hostname}";
    };
  };

  environment.systemPackages = [
    # Packages are now auto-imported from ./core/
    # Add any additional one-off packages here if needed
  ];

  services = {
    # Enable sound.
    pipewire = {
      enable = true;
      pulse.enable = true;
      wireplumber = {
        enable = true;
      };
    };
    #Enable SSH Server Daemon
    openssh = {
      enable = true;
    };
    printing = {
      enable = true;
    };
    gnome.gnome-keyring = {
      enable = true;
    };
    ollama = {
      enable = true;
    };
  };

  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
    daemon.settings = {
      data-root = "/home/${username}/docker";
      userland-proxy = false;
      experimental = true;
      metrics-addr = "0.0.0.0:9329";
      ipv6 = false;
    };
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
      };
    };
  };

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 10d";
  };

  system.stateVersion = "25.05";

}
