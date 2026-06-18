{
  nixpkgs,
  home-manager,
  nur,
  mangowm,
  import-tree,
  inputs,
  ...
}:

let
  # Helper function to create a host configuration
  mkHost =
    {
      hostname,
      username,
      platform ? "nixos",
      shownGpus ? [ ],
    }:
    nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit
          mangowm
          import-tree
          inputs
          hostname
          username
          platform
          ;
      };
      modules = [
        ./${hostname}/configuration.nix

        inputs.agenix.nixosModules.default

        {
          nixpkgs.overlays = [ nur.overlays.default ];
        }

        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            sharedModules = [ mangowm.hmModules.mango ];
            users.${username} = import ../home.nix;
            backupFileExtension = "backup";

            extraSpecialArgs = {
              inherit
                nur
                import-tree
                inputs
                username
                shownGpus
                ;
            };
          };
        }
      ];
    };
in
{
  phantom = mkHost {
    hostname = "phantom";
    username = "aaryan";
    platform = "nixos";
    shownGpus = [
      "nvidia"
      "intel"
    ];
  };
  # Future hosts go here:
}
