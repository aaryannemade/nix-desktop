{ pkgs, hostname, mangowm, ... }:

{
  imports = [
    mangowm.nixosModules.mango
  ];

  # X11 windowing system (kept for keymap/input infra; ly + Mango run Wayland)
  services.xserver.enable = true;

  services.displayManager.ly = {
    enable = true;
    settings = {
      animation = "matrix";
      bg = "0x00000000";
      fg = "0x00FFFFFF";
      border_fg = "0x00FFFFFF";
      error_fg = "0x00FFFFFF";
      cmatrix_fg = "0x00FFFFFF";
      cmatrix_head_col = "0x00FFFFFF";
      initial_info_text = "${hostname}";
      hide_version_string = true;
      clock = "%H:%M";
    };
  };

  programs.mango.enable = true;

  # Wayland utilities (Linux/Wayland-only).
  environment.systemPackages = with pkgs; [
    wl-clipboard
    wlr-randr
  ];
}
