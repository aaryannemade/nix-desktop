{
  description = "NixOS for Desktop";

  nixConfig = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [ "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4=" ];
  };

  inputs = {
    import-tree = {
      url = "github:denful/import-tree";
    };
    nixpkgs.url = "nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mangowm = {
      url = "github:mangowm/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia.url = "github:noctalia-dev/noctalia";

    nvim-config = {
      url = "github:lazyvim/starter";
      flake = false;
    };

    nur.url = "github:nix-community/nur";

  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      nur,
      mangowm,
      import-tree,
      ...
    }:
    {
      nixosConfigurations = import ./hosts {
        inherit
          nixpkgs
          home-manager
          nur
          mangowm
          import-tree
          inputs
          ;
      };

      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;
    };
}
