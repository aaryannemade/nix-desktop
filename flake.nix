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

    caveman = {
      url = "github:JuliusBrussee/caveman";
      flake = false;
    };

    nvim-config = {
      url = "github:lazyvim/starter";
      flake = false;
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
      };

      # Convenience package for the installer ISO:
      #   nix build .#installer-iso  ->  result/iso/nix-desktop-installer.iso
      packages.x86_64-linux.installer-iso =
        self.nixosConfigurations.installer.config.system.build.isoImage;

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

      # Build the generic, keyless WSL image. No SSH key is baked in; the image
      # seeds the repo into ~/nix-desktop on first boot so you can converge to a
      # real host with `nrs`. Requires root (uses sudo) because the underlying
      # tarballBuilder must set ownership inside the rootfs.
      #   Usage: nix run .#installer-wsl -- [output.wsl]   (default nixos.wsl)
      apps.x86_64-linux =
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          installerWslApp =
            let
              tarballBuilder =
                self.nixosConfigurations.installer-wsl.config.system.build.tarballBuilder;
              script = pkgs.writeShellApplication {
                name = "build-installer-wsl";
                runtimeInputs = [ pkgs.coreutils ];
                text = ''
                  out="''${1:-nixos.wsl}"
                  echo "[installer-wsl] Building generic image -> $out (requires sudo)"
                  sudo "${tarballBuilder}/bin/nixos-wsl-tarball-builder" "$out"
                  echo "[installer-wsl] Done: $out"
                '';
              };
            in
            {
              type = "app";
              program = "${script}/bin/build-installer-wsl";
            };
        in
        {
          installer-wsl = installerWslApp;
        };
    };
}
