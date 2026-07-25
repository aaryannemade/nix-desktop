{ ... }:

# Unfree allowance for Steam. The actual `programs.steam` enablement + compat
# packages stay in each host's configuration.nix (they differ per host); this
# only carries the allowlist entries so the predicate in system/shared/unfree.nix
# permits them.
{
  my.unfreePackages = [
    "steam"
    "steam-unwrapped"
  ];
}
