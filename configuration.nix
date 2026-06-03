{ config, inputs, lib, pkgs, mangowm, ... }:

{
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "nvidia-x11"
      "nvidia-settings"
    ];

  imports = [ 
    mangowm.nixosModules.mango
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "phantom";

  networking.networkmanager.enable = true;

  time.timeZone = "Asia/Calcutta";

  # Enable the X11 windowing system.
  # services.xserver.enable = false;
  services.xserver = {
      enable = true;
      autoRepeatDelay = 200;
      autoRepeatInterval = 35;

      videoDrivers = [ "modesetting" "nvidia" ];
  };

  services.displayManager.ly.enable = true;

  programs.mango.enable = true;

  hardware.graphics.enable = true;

  hardware.nvidia = {
    modesetting.enable = true;

    powerManagement.enable = false;
    powerManagement.finegrained = false;

    open = true;
    nvidiaSettings = true;

    package = config.boot.kernelPackages.nvidiaPackages.stable;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
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

  programs.zsh.enable = true;

  users.users.aaryan = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      packages = with pkgs; [
        tree
      ];
      shell = pkgs.zsh;
  };

  environment.shells = with pkgs; [ zsh ];

  environment.systemPackages = with pkgs; [
    neovim
    wget
    git
    curl
    bat
    wl-clipboard
    wlr-randr
    brightnessctl
    pulseaudio
    btop
    ncdu
    speedtest-cli
    asusctl
    power-profiles-daemon
    glab
  ];

  security.wrappers.btop = {
    owner = "root";
    group = "root";
    capabilities = "cap_perfmon+ep cap_dac_read_search+ep";
    source = "${pkgs.btop.override { cudaSupport = true; }}/bin/btop";
  };

  services = {
    # Enable asus laptop control
    asusd = {
      enable = true;
    };
    # Enable sound.
    pipewire = {
      enable = true;
      pulse.enable = true;
      wireplumber= {
        enable = true;
      };
    };
    # # Enable Bluetooth
    # blueman = {
    #   enable = true;
    # };
  };

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 10d";
  };

  boot.loader.systemd-boot.configurationLimit = 5;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # programs.firefox.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  system.stateVersion = "25.05";
}
