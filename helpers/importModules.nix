{ lib, ... }:

# Helper function to automatically import all .nix files from a directory
# Usage: importModules ./some-directory
# 
# This will import all .nix files in the directory except:
# - default.nix (to prevent infinite recursion)
# - Files ending in .disabled (for easy enabling/disabling)
#
# Returns: A list of paths to all matching .nix files
dir:
  let 
    inherit (lib) hasSuffix;
    inherit (builtins) readDir attrNames filter map;
    names = attrNames (readDir dir);
    nixFiles = filter (name:
      hasSuffix ".nix" name &&
      name != "default.nix"
    ) names;
  in
    map (name: dir + "/${name}") nixFiles
