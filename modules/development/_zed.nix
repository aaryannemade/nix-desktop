{
  lib,
  pkgs,
  platform,
  ...
}:

{
  home.packages = with pkgs; [
    nixd
  ];

  programs.zed-editor = {
    enable = true;

    package = lib.mkIf (platform != "nixos") null;

    extensions = [
      "nix"
      "toml"
      "rust"
      "catppuccin"
      "git-firefly"
      "catppuccin icons"
    ];
    userSettings = {
      theme = {
        mode = "dark";
        dark = "Catppuccin Mocha";
        light = "Catppuccin Latte";
      };
      hour_format = "hour12";
      vim_mode = true;
      ui_font_size = 18;
      icon_theme = "Catppuccin Macchiato";
      title_bar = {
        show_onboarding_banner = false;
        show_project_items = false;
        show_branch_name = false;
        show_user_menu = false;
      };
      tab_bar = {
        show = false;
      };
      toolbar = {
        quick_actions = false;
      };
      status_bar = {
        "experimental.show" = false;
      };
      project_panel = {
        dock = "right";
        default_width = 300;
      };
    };
  };
}
