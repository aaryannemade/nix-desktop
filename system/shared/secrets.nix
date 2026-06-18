{ ... }:

{
  # Decrypted at activation to /run/agenix/deepseek (tmpfs, never in store/git).
  # Owned by the user so opencode (home-manager) can read it via the
  # `{file:/run/agenix/deepseek}` reference in modules/ai/_opencode.nix.
  age.secrets.deepseek = {
    file = ../secrets/deepseek.age;
    owner = "aaryan";
    mode = "0400";
  };
}
