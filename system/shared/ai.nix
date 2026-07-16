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
    package = lib.mkDefault unstablePkgs.ollama;
    environmentVariables = {
      OLLAMA_CONTEXT_LENGTH = "98304";
    };
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
