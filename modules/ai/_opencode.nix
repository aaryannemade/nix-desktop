{
  pkgs,
  inputs,
  osConfig,
  ...
}:

let
  opencodeUnwrapped = inputs.opencode-nix.packages.${pkgs.stdenv.hostPlatform.system}.opencode;

  # herdr decides which agent lives in a pane by looking at the pane's
  # foreground process. Nix builds opencode with makeWrapper, which renames the
  # real executable to `.opencode-unwrapped` and leaves a shell script that
  # execs it -- so the foreground process herdr sees is `.opencode-unwrapped`,
  # not `opencode`. Detection fails, the pane is never claimed as an agent, and
  # nothing shows up in the Agents sidebar. The herdr-agent-state plugin still
  # connects and its `pane.report_agent` calls are ACKed, but herdr drops them
  # because the pane has no agent to attach state to.
  #
  # HERDR_AGENT is herdr's documented escape hatch for exactly this case (see
  # "VMs and sandbox wrappers" in https://herdr.dev/docs/agents/). It is read
  # from the foreground process's environment, so setting it on the wrapper
  # scopes the hint to opencode instead of every process in every pane -- which
  # is what `home.sessionVariables` would do.
  opencode = pkgs.symlinkJoin {
    name = "opencode-herdr-wrapped";
    paths = [ opencodeUnwrapped ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/opencode --set HERDR_AGENT opencode
    '';
  };
in

{
  home.packages = [ opencode ];

  xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    # Pinning avoids OpenCode's persistent @latest cache, which can leave an
    # older plugin version that ignores CLAUDE_CONFIG_DIR.
    plugin = [ "opencode-claude-auth@2.2.1" ];
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
