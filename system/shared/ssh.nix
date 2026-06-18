{ ... }:

{
  # SSH server, enabled on all platforms (NixOS, WSL, nix-darwin).
  services.openssh.enable = true;

  # NOTE: sshd hardening (e.g. settings.PasswordAuthentication = false) is
  # system-level and belongs here, NOT in Home Manager. Home Manager's
  # programs.ssh only configures the SSH *client*.
}
