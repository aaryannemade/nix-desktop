{ username, ... }:

{
  imports = [
    ./system
    ./services # Platform-dispatched on-demand services
  ];

  # Clear temporary files on every boot.
  boot.tmp.cleanOnBoot = true;

  nix.settings = {
    trusted-users = [
      username
    ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  system.stateVersion = "25.05";
}
