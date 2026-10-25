{
  pkgs,
  inputs,
  osConfig,
  ...
}:

let
  litellmURL = "https://llm.nerv-centr.xyz";
  litellmKey = "{file:${osConfig.age.secrets.litellm-api.path}}";
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
    # Pin npm plugins explicitly to avoid OpenCode's persistent @latest cache.
    # Claude auth 2.2.1 supports CLAUDE_CONFIG_DIR; LiteLLM 1.7.1 supports 1.x.
    plugin = [
      "opencode-claude-auth@2.2.1"
      "opencode-plugin-litellm@1.7.1"
    ];
    model = "openai/gpt-5.6-sol";
    small_model = "deepseek/deepseek-v4-flash";
    provider = {
      deepseek.options.apiKey = "{file:${osConfig.age.secrets.deepseek-api.path}}";
      opencode.options.apiKey = "{file:${osConfig.age.secrets.opencode-api.path}}";
      openrouter.options.apiKey = "{file:${osConfig.age.secrets.openrouter-api.path}}";
      minimax.options.apiKey = "{file:${osConfig.age.secrets.minimax-api.path}}";
      litellm = {
        name = "Nerv Centr (LiteLLM)";
        npm = "@ai-sdk/openai-compatible";
        options = {
          baseURL = "${litellmURL}/v1";
          apiKey = litellmKey;
        };
        # The plugin discovers models, limits, pricing, and capabilities from
        # LiteLLM at runtime, using the same resolved agenix key as completions.
      };
    };
    # The gateway aggregates Brave Search, Context7, GitHub, and GitLab, and
    # automatically exposes any additional servers allowed by this key.
    mcp.nerv-centr = {
      type = "remote";
      url = "${litellmURL}/mcp/";
      enabled = true;
      oauth = false;
      headers."x-litellm-api-key" = "Bearer ${litellmKey}";
      timeout = 30000;
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
