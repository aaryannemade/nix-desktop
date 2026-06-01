{
    description = "NixOS for Desktop";

    inputs = {
        nixpkgs.url = "nixpkgs/nixos-26.05";
        home-manager = {
            url = "github:nix-community/home-manager/release-26.05";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        mangowm = {
            url = "github:mangowm/mango";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        nur.url = "github:nix-community/nur";

    };

    outputs = { self, nixpkgs, home-manager, nur, ... }: {
        nixosConfigurations = import ./hosts {
          inherit nixpkgs home-manager nur;
        };
    };
}
