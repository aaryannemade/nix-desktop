{ pkgs, ... }:

{
    environment.systemPackages = with pkgs; [
        wget
        curl
        proton-vpn-cli
    ];

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
