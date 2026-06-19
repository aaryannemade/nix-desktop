{ lib, pkgs, ... }:

{
  # Work around systemd 260.1 failing to start user@UID.service in WSL when
  # delegated cgroup controllers are left enabled in cgroup.subtree_control.
  systemd.package = pkgs.systemd.overrideAttrs (old: {
    patches = old.patches ++ [
      (pkgs.fetchpatch {
        url = "https://github.com/systemd/systemd/pull/41304.patch";
        hash = "sha256-l/9YAl9cz662b0PAJOdXZODQRUlJbGYH9tVWqyfZ8Ws=";
      })
    ];
  });
}
