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
    { hostname, username }:
    nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit
          mangowm
          import-tree
          inputs
          hostname
          username
          ;
      };
      modules = [
        ./${hostname}/configuration.nix

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
  };
  # Future hosts go here:
}
