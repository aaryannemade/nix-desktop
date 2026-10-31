{
  config,
  pkgs,
  ...
}:

# Playwright MCP server for opencode, so agents can drive and inspect web apps.
#
# Uses Playwright's own patched Firefox (Gecko), not LibreWolf: Playwright's
# WebDriver BiDi mode for an installed browser (channel "moz-firefox" +
# executablePath) is rejected by LibreWolf ("openWindow() not supported in
# LibreWolf") and hangs on stock Firefox. The nixpkgs `playwright-mcp` wrapper
# pins PLAYWRIGHT_BROWSERS_PATH to the matching browsers in the Nix store, so
# there is no `npx`, no download, and no nix-ld required.
#
# For project test suites, use pkgs.playwright-driver.browsers in the
# project's devShell and pin @playwright/test to pkgs.playwright-driver.version.

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
      # Required: the nixpkgs wrapper sets PLAYWRIGHT_MCP_BROWSER=chromium,
      # which would otherwise override browserName from the config file.
      "--browser"
      "firefox"
      # Adds devtools tools (tracing, etc.) on top of the core tool set.
      "--caps"
      "devtools"
    ];
    enabled = true;
    timeout = 60000;
  };
}
