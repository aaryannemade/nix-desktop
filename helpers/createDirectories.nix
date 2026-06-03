{ lib, config, ... }:

# Helper function to create directories in home directory on activation
# Usage: createDirectories [ "path1" "path2/nested" ]
# 
# Directories will be created relative to $HOME
# If a directory already exists, it will be skipped (no error)
#
# Returns: A home.activation attribute set
directories:
  let
    inherit (lib.strings) concatMapStringsSep;
    
    # Generate mkdir commands for all directories
    mkdirCommands = concatMapStringsSep "\n" 
      (dir: ''mkdir -p "$HOME/${dir}"'') 
      directories;
  in
    lib.hm.dag.entryAfter [ "writeBoundary" ] mkdirCommands
