{ osConfig, ... }:

{
  my.opencode.providers.openrouter = {
    settings.apiKey = "{file:${osConfig.age.secrets.openrouter-api.path}}";
  };
}
