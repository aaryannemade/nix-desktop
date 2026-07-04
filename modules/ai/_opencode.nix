{
  pkgs,
  inputs,
  osConfig,
  ...
}:

{
  home.packages = [
    inputs.opencode.packages.${pkgs.system}.opencode
  ];

  xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    plugin = [ "opencode-claude-auth@latest" ];
    provider.deepseek.options.apiKey = "{file:${osConfig.age.secrets.deepseek.path}}";
    # caveman skills (skills-only, no plugin/hooks). The caveman flake input
    # ships a skills/ dir of SKILL.md folders; point opencode at it.
    skills.paths = [ "${inputs.caveman}/skills" ];
  };

  xdg.configFile."opencode/tui.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/tui.json";
    theme = "catppuccin";
  };
}
