# agenix recipient registry. NOT encrypted, safe to commit.
# Maps each .age secret to the public keys allowed to decrypt it.
#
# - User keys: let you (the human) edit secrets with `agenix -e`.
# - Host keys: let the machine decrypt at activation (-> /run/agenix/<name>).
#
# Shared-key multi-host model: list every host in `allHosts`. When adding a
# host, append its /etc/ssh/ssh_host_ed25519_key.pub here and rekey:
#   agenix -r   (re-encrypts all secrets to the updated recipient set)
let
  # User key: ~/.ssh/id_ed25519.pub
  aaryan = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPAtYcb36NJoUWDF/nBKjNtTbTQqrPTvyOXJ3SGtfxHg aaryan@phantom";

  # Host keys: /etc/ssh/ssh_host_ed25519_key.pub
  phantom = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINwHNRIdQaIZLFtpnbBMqr6RWU7Wf+JobXBwa3Jttyqs root@phantom";
  specter = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAwd5Nfaw0hUQ7IKqrJ3RH95IqhJAbF27pcu+7dF/F7a root@specter";
  banshee = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDfapYcOVwNEX6me+5ig8H+bJPEo9lVReSPya0XUTRKy root@banshee";

  users = [ aaryan ];
  allHosts = [
    phantom
    specter
    banshee
  ];
in
{
  "deepseek.age".publicKeys = users ++ allHosts;
}
