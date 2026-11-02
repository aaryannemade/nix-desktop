{ ... }:

# opencode providers, one module per provider/API key. Each sets
# my.opencode.providers.<id> (see modules/ai/_opencode.nix).
{
  imports = [
    ./_deepseek-provider.nix
    ./_hellish-dev-provider.nix
    ./_minimax-provider.nix
    ./_opencode-provider.nix
    ./_openrouter-provider.nix
  ];
}
