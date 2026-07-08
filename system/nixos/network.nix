{ hostname, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    proton-vpn-cli
  ];

  networking.networkmanager.enable = true;

  services = {
    avahi = {
      enable = true;
      ipv6 = false;
      nssmdns4 = true;
      openFirewall = true;
      publish = {
        enable = true;
        addresses = true;
        workstation = true;
      };
    };
  };
}
