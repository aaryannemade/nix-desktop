{ inputs, pkgs, ... }:

{
  nixpkgs.overlays = [ inputs.opendeck-nix.overlays.default ];

  environment.systemPackages = [ pkgs.opendeck ];
  services.udev.packages = [ pkgs.opendeck ];

  systemd.user.services.opendeck = {
    description = "OpenDeck";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.opendeck}/bin/opendeck --hide";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
