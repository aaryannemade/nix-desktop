{ username, ... }:

{
  imports = [
    ./system
    ./services # Platform-dispatched on-demand services
  ];

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
