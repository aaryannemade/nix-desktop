{ ... }:

{
  # nix-darwin Homebrew configuration. GUI macOS apps that are best installed
  # as casks (rather than Nix packages) are declared here, split by concern.
  imports = [
    ./_casks.nix
  ];
}
