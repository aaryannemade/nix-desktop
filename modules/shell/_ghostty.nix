{
  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      window-theme = "dark";
      # Noctalia writes the generated theme to ~/.config/ghostty/themes/noctalia
      # but can't edit this read-only store-managed config to activate it, so we
      # reference it by name here.
      theme = "noctalia";
    };
  };
}
