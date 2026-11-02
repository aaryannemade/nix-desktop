{ osConfig, ... }:

# hellish-dev MCP gateway for opencode (lives next to _playwright.nix). The gateway aggregates Brave Search,
# Context7, GitHub, and GitLab, and automatically exposes any additional
# servers allowed by this key. Merged into opencode.json's `mcp.servers` via
# my.opencode.mcp (modules/ai/_opencode.nix).
let
  gatewayUrl = "https://llm.hellish.dev/mcp/";
  apiKey = "{file:${osConfig.age.secrets.ag-api.path}}";
in
{
  my.opencode.mcp.hellish-dev = {
    type = "remote";
    url = gatewayUrl;
    oauth = false;
    headers."Authorization" = "Bearer ${apiKey}";
    timeout = {
      catalog = 30000;
      execution = 30000;
    };
  };
}
