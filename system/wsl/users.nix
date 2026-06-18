{ pkgs, username, ... }:

{
  # Placeholder WSL user config. WSL is NixOS, so this uses the same schema as
  # nixos/users.nix. `networkmanager` is dropped (no NM in WSL); add WSL-specific
  # groups (e.g. docker) as needed.
  users.defaultUserShell = pkgs.zsh;

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
    ];
    packages = with pkgs; [
      tree
    ];
    shell = pkgs.zsh;
  };
}
