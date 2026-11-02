{ osConfig, ... }:

{
  my.opencode.providers.minimax = {
    settings.apiKey = "{file:${osConfig.age.secrets.minimax-api.path}}";
  };
}
