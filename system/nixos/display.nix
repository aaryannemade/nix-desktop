{
  pkgs,
  hostname,
  mangowm,
  ...
}:

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

      # ly's own etc/config.ini ships `session_log = .local/state/ly-session.log`,
      # but the NixOS module builds config.ini from scratch (`defaultConfig //
      # cfg.settings`) and never includes this key, so ly falls back to its
      # compiled-in default and drops `~/ly-session.log` on every login. The
      # path is resolved relative to $HOME.
      session_log = ".local/state/ly-session.log";
    };
  };

  programs.mango = {
    enable = true;
    # Home-manager reuses this via osConfig (modules/window-managers/_mangowm.nix)
    # so the session binary and the HM config validator are the same build.
    package = mangowm.packages.${pkgs.stdenv.hostPlatform.system}.mango.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [
        # After a long suspend an NVIDIA output can briefly report a 0x0 mode
        # on resume; mango then aborts in wlr_swapchain_create
        # (`width > 0 && height > 0`), killing the session back to ly.
        # Defer the commit and retry instead. Drop once fixed upstream.
        ./_mango-patches/skip-zero-size-output-commit.patch
      ];
    });
  };

  # Wayland utilities (Linux/Wayland-only).
  environment.systemPackages = with pkgs; [
    wl-clipboard
    wlr-randr
  ];
}
