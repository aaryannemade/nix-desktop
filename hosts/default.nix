{ nixpkgs, home-manager, nur, ... }:

let
  # Helper function to create a host configuration
  mkHost = hostname: nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ./${hostname}/configuration.nix

      {
        nixpkgs.overlays = [ nur.overlays.default ];
      }

      home-manager.nixosModules.home-manager {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          users.aaryan = import ../home.nix;
          backupFileExtension = "backup";
          
          extraSpecialArgs = {
            inherit nur; 
          };
        };
      }
    ];
  };
in
{
  phantom = mkHost "phantom";
  # Future hosts go here:
}
