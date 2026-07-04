{
  description = "NixOS for Desktop";

  nixConfig = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
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

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mangowm = {
      url = "github:mangowm/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia.url = "github:noctalia-dev/noctalia";

    opencode = {
      url = "github:anomalyco/opencode";
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
          ;
      };

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

      # Build the specter WSL image with the host SSH key baked in.
      #   Usage: nix run .#specter-wsl [output.wsl]
      # Defaults output to ./specter.wsl. Requires root (uses sudo) because the
      # underlying tarballBuilder must set ownership inside the rootfs.
      apps.x86_64-linux.specter-wsl =
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          tarballBuilder = self.nixosConfigurations.specter.config.system.build.tarballBuilder;
          keyDir = "$HOME/wsl-key";
          script = pkgs.writeShellApplication {
            name = "build-specter-wsl";
            runtimeInputs = [ pkgs.coreutils ];
            text = ''
              out="''${1:-specter.wsl}"

              key_priv="${keyDir}/ssh_host_ed25519_key"
              key_pub="${keyDir}/ssh_host_ed25519_key.pub"

              if [ ! -f "$key_priv" ]; then
                echo "error: missing host private key at $key_priv" >&2
                exit 1
              fi

              # Stage an --extra-files tree containing the pre-seeded host key so
              # the image decrypts agenix secrets on first boot.
              extra="$(mktemp -d)"
              trap 'rm -rf "$extra"' EXIT
              mkdir -p "$extra/etc/ssh"
              install -m600 "$key_priv" "$extra/etc/ssh/ssh_host_ed25519_key"
              if [ -f "$key_pub" ]; then
                install -m644 "$key_pub" "$extra/etc/ssh/ssh_host_ed25519_key.pub"
              fi

              echo "[specter-wsl] Building image -> $out (requires sudo)"
              sudo "${tarballBuilder}/bin/nixos-wsl-tarball-builder" \
                --extra-files "$extra" \
                --chown /etc/ssh/ssh_host_ed25519_key 0:0 \
                "$out"

              echo "[specter-wsl] Done: $out"
            '';
          };
        in
        {
          type = "app";
          program = "${script}/bin/build-specter-wsl";
        };
    };
}
