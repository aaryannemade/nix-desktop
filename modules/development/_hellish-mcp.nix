{ osConfig, ... }:

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
