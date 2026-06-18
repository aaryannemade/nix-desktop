{ hostname, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    proton-vpn-cli
  ];

  networking.hostName = hostname;
  networking.networkmanager.enable = true;


  services = {
    avahi = {
      enable = true;
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
