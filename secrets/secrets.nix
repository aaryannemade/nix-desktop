# agenix recipient registry. NOT encrypted, safe to commit.
# Maps each .age secret to the public keys allowed to decrypt it.
#
# - User keys: let you edit secrets with
#   `nix run github:ryantm/agenix -- -e <secret>.age -i /etc/ssh/ssh_host_ed25519_key`.
# - Host keys: let the machine decrypt at activation (-> /run/agenix/<name>).
#
# Shared-key multi-host model: list every host in `allHosts`. When adding a
# host, append its /etc/ssh/ssh_host_ed25519_key.pub here and rekey:
#   nix run github:ryantm/agenix -- -r -i /etc/ssh/ssh_host_ed25519_key
#   (re-encrypts all secrets to the updated recipient set)
let
  # User key: ~/.ssh/id_ed25519.pub
  aaryan = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPAtYcb36NJoUWDF/nBKjNtTbTQqrPTvyOXJ3SGtfxHg aaryan@phantom";

  # Host keys: /etc/ssh/ssh_host_ed25519_key.pub
  phantom = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINwHNRIdQaIZLFtpnbBMqr6RWU7Wf+JobXBwa3Jttyqs root@phantom";
  wraith = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGJpx9cvjVGBELWEK6dbrOdBcDCk+p873aDP5hCfJHAp root@wraith";
  specter = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAwd5Nfaw0hUQ7IKqrJ3RH95IqhJAbF27pcu+7dF/F7a root@specter";
  banshee = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDfapYcOVwNEX6me+5ig8H+bJPEo9lVReSPya0XUTRKy root@banshee";

  users = [ aaryan ];
  allHosts = [
    phantom
    wraith
    specter
    banshee
  ];
in
{
  # API Keys
  "deepseek-api.age".publicKeys = users ++ allHosts;
  "opencode-api.age".publicKeys = users ++ allHosts;
  "openrouter-api.age".publicKeys = users ++ allHosts;

  # Git SSH Keys
  "git.age".publicKeys = users ++ allHosts;
  "git-burner.age".publicKeys = users ++ allHosts;

  # Local SSH Keys
  "nerv-centr.age".publicKeys = users ++ allHosts;
}
