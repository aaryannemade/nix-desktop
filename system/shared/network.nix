{ hostname, pkgs, ... }:

{
  networking.hostName = hostname;

  environment.systemPackages = with pkgs; [
    wget
    curl
  ];
}
