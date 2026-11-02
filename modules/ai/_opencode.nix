{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  # Upstream refreshes nix/hashes.json on `dev` after cutting a release, so the
  # node_modules hash shipped at a release tag is often stale ("hash mismatch
  # in fixed-output derivation ... opencode-node_modules"). Override it for
  # the pinned tag. When bumping the tag in flake.nix, set this to
  # lib.fakeHash, rebuild, and paste the "got:" hash (or drop the override if
  # upstream's hash matches).
  nodeModulesHash = "sha256-+GgLX4lq8fPOJVoDGp220uiCTLB0ZwrBkcNo36q9MZU=";
  opencodeUnwrapped =
    inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.opencode.overrideAttrs
      (old: {
        node_modules = old.node_modules.override { hash = nodeModulesHash; };
      });

  # herdr decides which agent lives in a pane by looking at the pane's
  # foreground process. Nix wraps opencode (upstream's package and the
  # wrapProgram below), which renames the real executable to
  # `.opencode-wrapped` -- so the foreground process herdr sees is not
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
  options.my.opencode = {
    # opencode MCP servers, one module per server: modules/development/
    # _hellish-mcp.nix (all platforms) and _playwright.nix (NixOS only).
    # Written as `mcp.servers` of opencode.json below, so entries must use the
    mcp = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "opencode MCP server definitions (V2 shape), keyed by server name.";
    };
    # opencode providers, one module per provider/API key: modules/ai/providers/.
    # Written as `providers` of opencode.json below (V2 shape: `package`,
    # `settings`, `models`).
    providers = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "opencode provider definitions (V2 shape), keyed by provider ID.";
    };
    # Terminal-client plugins contributed by other modules, e.g. herdr's TUI
    # integration (modules/development/_herdr.nix). Written to cli.json.
    cliPlugins = lib.mkOption {
      type = lib.types.listOf lib.types.anything;
      default = [ ];
      description = "Additional opencode terminal-client plugins for cli.json.";
    };
  };

  config = {
    home.packages = [ opencode ];

    # Native OpenCode 2 config shape (https://opencode.ai/v2/docs/migrate-v1).
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
