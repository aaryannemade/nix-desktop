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

  age.secrets.opencode-api = {
    file = ../../secrets/opencode-api.age;
    owner = username;
    mode = "0400";
  };

  # Git SSH auth keys. Consumed by Home Manager's programs.ssh (see
  # modules/development/_git-config.nix) via osConfig.age.secrets.<name>.path.
  # Mode 0600 is required: ssh refuses to use a private key with looser perms.
  age.secrets.gitlab-main = {
    file = ../../secrets/gitlab-main.age;
    owner = username;
    mode = "0600";
  };

  age.secrets.gitlab-burner = {
    file = ../../secrets/gitlab-burner.age;
    owner = username;
    mode = "0600";
  };

  age.secrets.github-main = {
    file = ../../secrets/github-main.age;
    owner = username;
    mode = "0600";
  };

  age.secrets.github-burner = {
    file = ../../secrets/github-burner.age;
    owner = username;
    mode = "0600";
  };
}
