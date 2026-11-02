{ osConfig, ... }:

{
  my.opencode.providers.deepseek = {
    settings.apiKey = "{file:${osConfig.age.secrets.deepseek-api.path}}";
  };
}
