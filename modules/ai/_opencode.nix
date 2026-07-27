{
  pkgs,
  inputs,
  osConfig,
  ...
}:

{
  home.packages = [
    inputs.opencode-nix.packages.${pkgs.stdenv.hostPlatform.system}.opencode
  ];

  xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    plugin = [ "opencode-claude-auth@latest" ];
    model = "openai/gpt-5.6-sol";
    small_model = "deepseek/deepseek-v4-flash";
    provider = {
      deepseek.options.apiKey = "{file:${osConfig.age.secrets.deepseek-api.path}}";
      opencode.options.apiKey = "{file:${osConfig.age.secrets.opencode-api.path}}";
      openrouter.options.apiKey = "{file:${osConfig.age.secrets.openrouter-api.path}}";
    };
    # caveman skills (skills-only, no plugin/hooks). The caveman flake input
    # ships a skills/ dir of SKILL.md folders; point opencode at it.
    skills.paths = [ "${inputs.caveman}/skills" ];
  };

  xdg.configFile."opencode/tui.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/tui.json";
    theme = "catppuccin";
  };
}
