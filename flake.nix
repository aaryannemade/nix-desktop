{
    description = "NixOS for Desktop";

    inputs = {
        nixpkgs.url = "nixpkgs/nixos-25.05";
        home-manager = {
            url = "github:nix-community/home-manager/release-25.05";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        nur.url = "github:nix-community/nur";

    };

    outputs = { self, nixpkgs, home-manager, nur, ... }: {
        nixosConfigurations.phantom = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
                ./configuration.nix

                {
                  nixpkgs.overlays =  [
                    nur.overlays.default
                  ];
                }

                home-manager.nixosModules.home-manager {
                    home-manager = {
                        useGlobalPkgs = true;
                        useUserPackages = true;
                        users.aaryan = import ./home.nix;
                        backupFileExtension = "backup";

                        extraSpecialArgs = {
                          inherit nur;
                        };
                    };
                }
            ];
        };
    };
}
