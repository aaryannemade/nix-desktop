{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    apfs-fuse
  ];
}
