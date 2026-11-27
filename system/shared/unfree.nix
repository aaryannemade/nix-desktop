{ config, lib, ... }:

# Central unfree allowlist.
#
# `allowUnfreePredicate` is a *function*, so it can only be defined once and
# cannot be merged across modules. Instead, any module that installs an unfree
# package appends its name to the `my.unfreePackages` list option, right next
# to the package itself, and this file turns the accumulated list into the
# single predicate. Importing the module is all it takes.
#
# The option exists in both module systems:
#   NixOS modules:         { my.unfreePackages = [ "steam" ]; }
#   home-manager modules:  { my.unfreePackages = [ "davinci-resolve" ]; }
# home-manager uses the system pkgs (useGlobalPkgs), so every user's list is
# merged into the system predicate here.
let
  unfreeOption = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    example = [
      "nvidia-x11"
      "steam"
    ];
    description = "Unfree package names (lib.getName) permitted on this host.";
  };

  hmUnfreePackages = lib.concatMap (user: user.my.unfreePackages) (
    lib.attrValues config.home-manager.users
  );
in
{
  options.my.unfreePackages = unfreeOption;

  config = {
    home-manager.sharedModules = [
      { options.my.unfreePackages = unfreeOption; }
    ];

    nixpkgs.config.allowUnfreePredicate =
      pkg: builtins.elem (lib.getName pkg) (config.my.unfreePackages ++ hmUnfreePackages);
  };
}
