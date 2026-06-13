{ pkgs, inputs, ... }:

{
  home.packages = with pkgs; [
    opencode
  ];

  xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    plugin = [ "opencode-claude-auth@latest" ];
    provider.deepseek.options.apiKey = "sk-b51b95ba7cc94627bc70e6b35457b8d1";
    # caveman skills (skills-only, no plugin/hooks). The caveman flake input
    # ships a skills/ dir of SKILL.md folders; point opencode at it.
    skills.paths = [ "${inputs.caveman}/skills" ];
  };

  xdg.configFile."opencode/tui.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/tui.json";
    theme = "catppuccin";
  };
}
