{
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  blenderMcp = pkgs.callPackage ./_blender-mcp-package.nix { };
  blenderVersion = lib.versions.majorMinor pkgs.blender.version;
in
{
  config =
    lib.mkIf
      (builtins.elem osConfig.networking.hostName [
        "wraith"
        "phantom"
      ])
      {
        home.packages = [ blenderMcp ];

        # User add-ons are discovered by the existing CUDA Blender binary. Do not
        # override/wrap Blender: that would unnecessarily change its cached package.
        xdg.configFile."blender/${blenderVersion}/scripts/addons/blender_mcp.py".source =
          "${blenderMcp}/share/blender-mcp/blender_mcp.py";

        my.opencode.mcp.blender = {
          type = "local";
          command = [ (lib.getExe blenderMcp) ];
          environment = {
            BLENDER_HOST = "localhost";
            BLENDER_PORT = "9876";
            BLENDER_MCP_SAFE_MODE = "1";
            DISABLE_TELEMETRY = "true";
          };
          timeout = {
            catalog = 60000;
            execution = 600000;
          };
        };
      };
}
