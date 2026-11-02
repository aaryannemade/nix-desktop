{
  config,
  pkgs,
  ...
}:

# Playwright MCP server for opencode, so agents can drive and inspect web apps.

let
  playwrightMcpConfig = pkgs.writeText "playwright-mcp.json" (
    builtins.toJSON {
      browser = {
        browserName = "firefox";
        # Fresh in-memory profile per session; avoids profile lock conflicts
        # when several agents run in parallel.
        isolated = true;
        launchOptions = {
          # Set to false to watch the agent drive the browser.
          headless = true;
        };
        contextOptions.viewport = {
          width = 1920;
          height = 1080;
        };
      };
      # Auto-named screenshots, traces, etc.
      outputDir = "${config.xdg.cacheHome}/playwright-mcp";
    }
  );
in
{
  home.packages = [ pkgs.playwright-mcp ];

  my.opencode.mcp.playwright = {
    type = "local";
    command = [
      "${pkgs.playwright-mcp}/bin/playwright-mcp"
      "--config"
      "${playwrightMcpConfig}"
      "--browser"
      "firefox"
      # Adds devtools tools (tracing, etc.) on top of the core tool set.
      "--caps"
      "devtools"
    ];
    timeout = {
      catalog = 60000;
      execution = 60000;
    };
  };
}
