{ config, lib, ... }:

# Central unfree allowlist.
#
# `allowUnfreePredicate` is a *function*, so it can only be defined once and
# cannot be merged across modules. To let independent feature modules (see
# hosts/overrides/) each contribute their own unfree package(s), they append
# names to the `my.unfreePackages` list option and this file turns the
# accumulated list into the single predicate.
#
# Usage from an override module:
#   { ... }: { my.unfreePackages = [ "blender" ]; }
{
  options.my.unfreePackages = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    example = [ "nvidia-x11" "steam" ];
    description = "Unfree package names (lib.getName) permitted on this host.";
  };

  config.nixpkgs.config.allowUnfreePredicate =
    pkg: builtins.elem (lib.getName pkg) config.my.unfreePackages;
}
