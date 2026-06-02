{ nixpkgs, home-manager, nur, mangowm, inputs, ... }:

let
  # Helper function to create a host configuration
  mkHost = hostname: nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {
    	inherit mangowm;
    };
    modules = [
      ./${hostname}/configuration.nix

      {
        nixpkgs.overlays = [ nur.overlays.default ];
      }

      home-manager.nixosModules.home-manager {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
	  sharedModules = [ mangowm.hmModules.mango ];
          users.aaryan = import ../home.nix;
          backupFileExtension = "backup";
          
          extraSpecialArgs = {
            inherit nur inputs;
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
