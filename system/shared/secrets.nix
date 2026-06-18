{ username, ... }:

{
  # Decrypted at activation (tmpfs, never in store/git). Owned by the user so
  # opencode (home-manager) can read it. The consumer references the resolved
  # path via osConfig.age.secrets.deepseek.path (see modules/ai/_opencode.nix),
  # so this stays platform-agnostic.
  #
  # NOTE: the agenix MODULE is imported per-platform in hosts/default.nix
  # (agenix.nixosModules.default for NixOS/WSL; agenix.darwinModules.default
  # for a future macOS host). This declaration itself is shared.
  age.secrets.deepseek = {
    file = ../../secrets/deepseek.age;
    owner = username;
    mode = "0400";
  };
}
