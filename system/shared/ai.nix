{
  lib,
  platform,
  unstablePkgs,
  ...
}:

# Ollama, set up per-platform from one shared file.
#
# NixOS + WSL: use the native `services.ollama` module. It is NixOS-only, so it
# is guarded with optionalAttrs (mkIf would still declare the option path and
# error on darwin).
#
# darwin (macOS): there is no `services.ollama` module. Install the package and
# run it as a launchd user agent instead. nix-darwin exposes `launchd.user.agents`.
lib.optionalAttrs (platform == "nixos" || platform == "wsl") {
  services.ollama = {
    enable = true;
    host = "0.0.0.0";
    openFirewall = true;
    package = lib.mkDefault unstablePkgs.ollama;
    environmentVariables = {
      OLLAMA_KEEP_ALIVE = "15m";
      OLLAMA_CONTEXT_LENGTH = "32768";
      # Flash attention is required for a quantized KV cache. q8_0 roughly halves
      # KV-cache VRAM vs f16 with negligible quality loss.
      OLLAMA_FLASH_ATTENTION = "1";
      OLLAMA_KV_CACHE_TYPE = "q8_0";
      OLLAMA_ORIGINS = "http://192.168.64.*,https://192.168.64.*";
    };
    # test key for litellm: sk-zzwW1Kf4azzSkCAnvbyi9Q
  };
}
// lib.optionalAttrs (platform == "darwin") {
  environment.systemPackages = [ unstablePkgs.ollama ];

  launchd.user.agents.ollama = {
    command = "${unstablePkgs.ollama}/bin/ollama serve";
    serviceConfig = {
      KeepAlive = true;
      RunAtLoad = true;
    };
  };
}
