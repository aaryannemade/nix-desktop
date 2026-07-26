{
  self,
  nixpkgs,
}:

let
  system = "x86_64-linux";
  pkgs = nixpkgs.legacyPackages.${system};

  bundlePath = builtins.getEnv "NIX_DESKTOP_GIT_BUNDLE";
  repoBundle =
    if bundlePath == "" then
      null
    else
      builtins.path {
        path = bundlePath;
        name = "nix-desktop.bundle";
      };

  buildInputs = [
    pkgs.coreutils
    pkgs.git
    pkgs.nix
  ];

  # Create a full-history bundle from committed HEAD. Rejecting dirty tracked
  # files prevents the image configuration and embedded checkout disagreeing.
  bundleSetup = ''
    repo="$(git rev-parse --show-toplevel)"
    if ! git -C "$repo" diff --quiet || ! git -C "$repo" diff --cached --quiet; then
      echo "error: commit tracked changes before building an image" >&2
      exit 1
    fi

    bundle="$(mktemp --suffix=.bundle)"
    trap 'rm -f "$bundle"' EXIT
    git -C "$repo" bundle create "$bundle" --all
    git bundle verify "$bundle"
  '';

  installerIsoApp =
    let
      script = pkgs.writeShellApplication {
        name = "build-installer-iso";
        runtimeInputs = buildInputs;
        text = ''
          ${bundleSetup}
          echo "[installer-iso] Building image from $(git -C "$repo" rev-parse --short HEAD)"
          (
            cd "$repo"
            NIX_DESKTOP_GIT_BUNDLE="$bundle" \
              nix build --impure .#installer-iso --out-link result
          )
          echo "[installer-iso] Done: $repo/result/iso/"
        '';
      };
    in
    {
      type = "app";
      program = "${script}/bin/build-installer-iso";
    };

  installerWslApp =
    let
      script = pkgs.writeShellApplication {
        name = "build-installer-wsl";
        runtimeInputs = buildInputs ++ [ pkgs.sudo ];
        text = ''
          out="''${1:-nixos.wsl}"
          if [[ "$out" != /* ]]; then
            out="$PWD/$out"
          fi

          ${bundleSetup}
          echo "[installer-wsl] Building image from $(git -C "$repo" rev-parse --short HEAD) -> $out"
          builder="$(
            cd "$repo"
            NIX_DESKTOP_GIT_BUNDLE="$bundle" \
              nix build --impure --no-link --print-out-paths \
                .#nixosConfigurations.installer-wsl.config.system.build.tarballBuilder
          )"
          sudo "$builder/bin/nixos-wsl-tarball-builder" "$out"
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
  inherit repoBundle;

  packages = {
    # Low-level package used by CI and by the exact-revision app above.
    installer-iso = self.nixosConfigurations.installer.config.system.build.isoImage;
  };

  apps = {
    installer-iso = installerIsoApp;
    installer-wsl = installerWslApp;
  };
}
