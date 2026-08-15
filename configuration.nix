{ username, ... }:

{
  imports = [
    ./system
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
