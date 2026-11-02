{ osConfig, ... }:

{
  my.opencode.providers.opencode = {
    settings.apiKey = "{file:${osConfig.age.secrets.opencode-api.path}}";
  };
}
