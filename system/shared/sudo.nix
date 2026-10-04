{ ... }:

{
  # Show an asterisk for each character typed at the sudo password prompt.
  security.sudo.extraConfig = ''
    Defaults pwfeedback
  '';
}
