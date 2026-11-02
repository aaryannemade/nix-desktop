{
  description = "NixOS for Desktop";

  nixConfig = {
    extra-substituters = [
      "https://noctalia.cachix.org"
      "https://cache.nixos-cuda.org"
      "https://adithyagenie.cachix.org"
      "https://cache.lantian.pub/lantian"
    ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
      "adithyagenie.cachix.org-1:h6BSMboeVfxyrULWuRQqAyweo4AJRATekb88xotfQwc="
      "lantian:WVGO7vsRMSEN+h7Lp7kv6SAmrkEXgUGbbXm7jMDjBuQ="
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

    # CachyOS kernels (system/nixos/kernel.nix). The `release` branch only
    # advances after upstream's Hydra has built (and cached) the kernels, NVIDIA
    # test configs included. Deliberately NOT following our nixpkgs: its
    # `pinned` overlay builds against its own nixos-unstable-small pin, which
    # is what the binary cache contains. That pin also supplies the NVIDIA
    # driver, so `nix flake update nix-cachyos-kernel` bumps kernel + driver.
    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel/release";
    };

    opendeck-nix = {
      url = "github:Yeradon/opendeck-nix";
    };

    # Official opencode flake. Builds from source (bun) -- upstream publishes
    # no binary cache (anomalyco/opencode#22500, closed not planned), so each
    # bump compiles locally. Pinned to a release tag because the default
    # branch is `dev`. Bump by editing the tag, then `nix flake update opencode`.
    # Deliberately NOT following our nixpkgs: the build needs nixpkgs'
    # `models-dev` and bun at versions upstream has tested against.
    opencode = {
      url = "github:anomalyco/opencode/v2.2.5";
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

    skills-hub = {
      url = "github:aaryannemade/agent-skills";
      inputs.nixpkgs.follows = "nixpkgs";
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
