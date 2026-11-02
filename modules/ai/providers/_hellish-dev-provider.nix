{ osConfig, ... }:

# OpenAI-compatible endpoint of the hellish-dev gateway. The same gateway's
# MCP endpoint is in modules/development/_hellish-mcp.nix.
{
  my.opencode.providers.hellish-dev = {
    name = "hellish-dev";
    package = "@opencode/ai/providers/openai-compatible";
    settings = {
      baseURL = "https://llm.hellish.dev/v1";
      apiKey = "{file:${osConfig.age.secrets.ag-api.path}}";
    };
    models = {
      "glm5.3-flash" = {
        name = "GLM 5.3 Flash";
      };
    };
  };
}
