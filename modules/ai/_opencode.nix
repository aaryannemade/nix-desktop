{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  opencodeUnwrapped = inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.opencode;

  # herdr decides which agent lives in a pane by looking at the pane's
  # foreground process. Nix wraps opencode (the opencode-nix package and the
  # wrapProgram below), which renames the real executable to
  # `.opencode-unwrapped` / `.opencode-wrapped` -- so the foreground process herdr sees is not
  # `opencode`. Detection fails, the pane is never claimed as an agent, and
  # nothing shows up in the Agents sidebar. The herdr integration still
  # connects and its `pane.report_agent` calls are ACKed, but herdr drops them
  # because the pane has no agent to attach state to.
  #
  # HERDR_AGENT is herdr's documented escape hatch for exactly this case (see
  # "VMs and sandbox wrappers" in https://herdr.dev/docs/agents/). It is read
  # from the foreground process's environment, so setting it on the wrapper
  # scopes the hint to opencode instead of every process in every pane -- which
  # is what `home.sessionVariables` would do.
  #
  # opencode 2's native clipboard backend dlopen()s libwayland-client.so.0 at
  # runtime. NixOS has no global library path, so without it on
  # LD_LIBRARY_PATH the host clipboard is unavailable and pasting images with
  # ctrl+v silently does nothing (text still pastes via the terminal).
  opencode = pkgs.symlinkJoin {
    name = "opencode-herdr-wrapped";
    paths = [ opencodeUnwrapped ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/opencode \
        --set HERDR_AGENT opencode \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ pkgs.wayland ]}
    '';
  };
in

{
  options.my.opencode = {
    # opencode MCP servers
    mcp = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "opencode MCP server definitions, keyed by server name.";
    };
    # opencode llm provider
    providers = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "opencode provider definitions, keyed by provider ID.";
    };
    # Terminal-client plugin
    cliPlugins = lib.mkOption {
      type = lib.types.listOf lib.types.anything;
      default = [ ];
      description = "Additional opencode terminal-client plugins for cli.json.";
    };
  };

  config = {
    home.packages = [ opencode ];

    xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
      "$schema" = "https://opencode.ai/config.json";
      # opencode-claude-auth 3.x is the V2 build (2.2.1 was the last for V1).
      plugins = [
        "opencode-claude-auth@latest"
      ];
      model = "openai/gpt-6.1-sol";
      update = "disable";
      agents = {
        title.model = "deepseek/deepseek-v4-pro";
      };
      permissions = [
        {
          action = "external_directory";
          resource = "*";
          effect = "ask";
        }
        {
          action = "external_directory";
          resource = "/tmp/*";
          effect = "allow";
        }
      ];
      experimental = {
        todo = true;
      };
      providers = config.my.opencode.providers;
      mcp.servers = config.my.opencode.mcp;
      skills = [ "${config.xdg.configHome}/agents/skills" ];
    };

    xdg.configFile."opencode/cli.json".text = builtins.toJSON {
      "$schema" = "https://opencode.ai/v2/cli.json";
      theme.name = "catppuccin";
      plugins = config.my.opencode.cliPlugins;
    };
  };
}
