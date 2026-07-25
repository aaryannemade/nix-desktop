{
  nixpkgs,
  home-manager,
  mangowm,
  import-tree,
  inputs,
  self,
  ...
}:

let
  # Helper function to create a host configuration
  #
  # homeDirectory is optional. When omitted it defaults to the standard path
  # for the platform (/Users/<username> on darwin, /home/<username> otherwise).
  # On the darwin platform it can be explicitly stated, e.g. when the macOS home
  # lives on an external drive (homeDirectory = "/Volumes/external-home/...").
  mkHost =
    {
      hostname,
      username,
      platform ? "nixos",
      homeDirectory ? null,
      shownGpus ? [ ],
    }:
    let
      unstablePkgs = import inputs.nixpkgs-unstable {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };
      effectiveHomeDirectory =
        if homeDirectory != null then
          homeDirectory
        else if platform == "darwin" then
          "/Users/${username}"
        else
          "/home/${username}";
    in
    nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit
          mangowm
          import-tree
          inputs
          hostname
          username
          platform
          unstablePkgs
          ;
        homeDirectory = effectiveHomeDirectory;
      };
      modules = [
        ./${hostname}/configuration.nix

        # agenix module is platform-specific: nixosModules.default for NixOS/WSL.
        # A future macOS (nix-darwin) host must use agenix.darwinModules.default
        # instead. The shared system/shared/secrets.nix declaration stays the same.
        inputs.agenix.nixosModules.default

        home-manager.nixosModules.home-manager
      ]
      # NixOS-WSL module: only pulled in for WSL hosts. It provides `wsl.enable`,
      # the WSL boot/init machinery, and the Windows<->Linux interop layer.
      ++ nixpkgs.lib.optional (platform == "wsl") inputs.nixos-wsl.nixosModules.default
      ++ [
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            sharedModules = [ mangowm.hmModules.mango ];
            users.${username} = import ../home.nix;
            backupFileExtension = "backup";

            extraSpecialArgs = {
              inherit
                import-tree
                inputs
                username
                shownGpus
                platform
                ;
              homeDirectory = effectiveHomeDirectory;
            };
          };
        }
      ];
    };
in
{
  phantom = mkHost {
    hostname = "phantom";
    username = "aaryan";
    platform = "nixos";
    shownGpus = [
      "nvidia"
      "intel"
    ];
  };

  specter = mkHost {
    hostname = "specter";
    username = "aaryan";
    platform = "wsl";
    shownGpus = [
      "nvidia"
      "intel"
    ];
  };

  banshee = mkHost {
    hostname = "banshee";
    username = "aaryan";
    platform = "wsl";
    shownGpus = [
      "nvidia"
      "intel"
    ];
  };
  wraith = mkHost {
    hostname = "wraith";
    username = "aaryan";
    platform = "nixos";
    shownGpus = [
      "nvidia"
      "intel"
    ];
  };

  # Thin custom installer ISO. Not a normal host: no per-host hardware config,
  # no home-manager/agenix — just a minimal live image carrying a read-only copy
  # of this repo plus the `nix-desktop-install` helper.
  # Build: nix build .#installer-iso
  installer = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs self; };
    modules = [ ./installer/configuration.nix ];
  };

  # Generic, keyless WSL image. Standalone (does not use mkHost): minimal,
  # secret-free, carries a read-only copy of the repo and seeds ~/nix-desktop on
  # first boot. Converge to a real host after import with `nrs`.
  # Build: nix run .#installer-wsl -- [out.wsl]
  installer-wsl = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs self; };
    modules = [ ./installer-wsl/configuration.nix ];
  };

  # Future hosts go here:
}
