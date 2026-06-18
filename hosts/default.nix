{ nixpkgs, home-manager, nur, mangowm, import-tree, inputs, ... }:

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
          ;
        homeDirectory = effectiveHomeDirectory;
      };
      modules = [
        ./${hostname}/configuration.nix

        # agenix module is platform-specific: nixosModules.default for NixOS/WSL.
        # A future macOS (nix-darwin) host must use agenix.darwinModules.default
        # instead. The shared system/shared/secrets.nix declaration stays the same.
        inputs.agenix.nixosModules.default

        {
          nixpkgs.overlays = [ nur.overlays.default ];
        }

        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            sharedModules = [ mangowm.hmModules.mango ];
            users.${username} = import ../home.nix;
            backupFileExtension = "backup";

            extraSpecialArgs = {
              inherit
                nur
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
  # Future hosts go here:
}
