{ ... }:

# Allow the free DaVinci Resolve (unfree license) installed by
# modules/production/_davinci-resolve.nix. Import from hosts that run it.
{
  my.unfreePackages = [ "davinci-resolve" ];
}
