{ pkgs, username, ... }:

{
  # Placeholder nix-darwin user config. macOS uses a DIFFERENT users schema than
  # NixOS: there is no `isNormalUser`, no `extraGroups` in the same form, and no
  # `users.defaultUserShell`. The user account is typically created by macOS
  # itself; nix-darwin only manages a subset of fields.
  #
  # Fill in when wiring up darwin. Example shape:
  #
  # users.users.${username} = {
  #   home = "/Users/${username}";
  #   shell = pkgs.zsh;
  # };
}
