{ pkgs, username, homeDirectory, ... }:

{
  # nix-darwin user config. macOS uses a DIFFERENT users schema than NixOS:
  # there is no `isNormalUser`, no `extraGroups` in the same form, and no
  # `users.defaultUserShell`. The user account is typically created by macOS
  # itself; nix-darwin only manages a subset of fields.
  #
  # `home` must match what macOS reports as the user's home directory so that
  # nix-darwin and Home Manager agree. `homeDirectory` is computed per-host in
  # hosts/default.nix and can be explicitly set on darwin 
  # (e.g. an external drive home like /Volumes/external-home/...).
  users.users.${username} = {
    home = homeDirectory;
    shell = pkgs.zsh;
  };
}
