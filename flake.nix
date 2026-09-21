{
  description = "NixOS for Desktop";

  nixConfig = {
    extra-substituters = [
      "https://noctalia.cachix.org"
      "https://cache.nixos-cuda.org"
      "https://adithyagenie.cachix.org"
    ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
      "adithyagenie.cachix.org-1:h6BSMboeVfxyrULWuRQqAyweo4AJRATekb88xotfQwc="
    ];
  };

  inputs = {
    import-tree = {
      url = "github:denful/import-tree";
    };

    nixpkgs = {
      url = "nixpkgs/nixos-26.05";
    };

    nixpkgs-unstable = {
      url = "nixpkgs/nixos-unstable";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    blender-cuda = {
      url = "github:adithyagenie/blender-cuda-nixos";
    };

    mangowm = {
      url = "github:mangowm/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia";
    };

    opendeck-nix = {
      url = "github:Yeradon/opendeck-nix";
    };

    opencode-nix = {
      url = "github:dominicnunez/opencode-nix";
    };

    helium = {
      url = "github:AlvaroParker/helium-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Terminal workspace manager for AI coding agents.
    # Deliberately NOT following our nixpkgs: herdr pins nixos-unstable plus a
    # rust-overlay toolchain from its rust-toolchain.toml. Forcing it onto our
    # stable nixpkgs is untested upstream and risks a full Rust rebuild.
    herdr = {
      url = "github:herdrdev/herdr";
    };

    # oh-my-zsh upstream, tracked directly rather than via nixpkgs. The nixpkgs
    # snapshot lags well behind: 26.05 ships 2026-02-19 and even nixos-unstable
    # only has 2026-08-16, both older than the `herdr` plugin which landed
    # upstream on 2026-09-10. Consumed in modules/shell/_zsh.nix, which swaps
    # this in as `src` so nixpkgs still owns the Nix-specific patching.
    # Locked in flake.lock; bump with `nix flake update ohmyzsh`.
    ohmyzsh = {
      url = "github:ohmyzsh/ohmyzsh";
      flake = false;
    };

    caveman = {
      url = "github:JuliusBrussee/caveman";
      flake = false;
    };

    nvim-config = {
      url = "github:lazyvim/starter";
      flake = false;
    };

    nvf = {
      url = "github:NotAShelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      mangowm,
      import-tree,
      ...
    }:
    let
      imageOutputs = import ./images {
        inherit self nixpkgs;
      };
    in
    {
      nixosConfigurations = import ./hosts {
        inherit
          nixpkgs
          home-manager
          mangowm
          import-tree
          inputs
          self
          ;
        repoBundle = imageOutputs.repoBundle;
      };

      packages.x86_64-linux = imageOutputs.packages;
      apps.x86_64-linux = imageOutputs.apps;

      formatter.x86_64-linux =
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
        in
        pkgs.writeShellApplication {
          name = "nixfmt-tree";
          runtimeInputs = [
            pkgs.nixfmt
            pkgs.findutils
          ];
          text = ''
            if [ "$#" -eq 0 ]; then
              set -- .
            fi
            find "$@" -type f -name '*.nix' -print0 | xargs -0 -r nixfmt
          '';
        };
    };
}
