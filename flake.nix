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

        quickshell = {
          url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
          inputs.nixpkgs.follows = "nixpkgs";
        };

        nvim-config = {
          url = "github:tonybanters/nvim";
          flake = false;
        };

        quickshell-config = {
          url = "gitlab:aaryandesignsgames/quickshell-dummy";
          flake = false;
        };

        nur.url = "github:nix-community/nur";

    };

    outputs = inputs@{ self, nixpkgs, home-manager, nur, mangowm, ... }: {
        nixosConfigurations = import ./hosts {
          inherit nixpkgs home-manager nur mangowm inputs;
        };

        formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;
    };
}
