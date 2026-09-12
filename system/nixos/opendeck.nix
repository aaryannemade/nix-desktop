{ inputs, pkgs, ... }:

let
  opendeck = inputs.opendeck-nix.packages.${pkgs.stdenv.hostPlatform.system}.opendeck;
in
{
  environment.systemPackages = [ opendeck ];
  services.udev.packages = [ opendeck ];

  systemd.user.services.opendeck = {
    description = "OpenDeck";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];

    serviceConfig = {
      ExecStart = "${opendeck}/bin/opendeck --hide";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
