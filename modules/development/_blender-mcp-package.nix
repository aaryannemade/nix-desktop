{
  lib,
  python3Packages,
  fetchPypi,
}:

python3Packages.buildPythonApplication rec {
  pname = "mcp-for-blender";
  version = "2.2.8";
  pyproject = true;

  src = fetchPypi {
    pname = "mcp_for_blender";
    inherit version;
    hash = "sha256-YvVi/bJsaotwOynZIjpA7htC1LOEolp4FLG+q3P7XtA=";
  };

  build-system = with python3Packages; [
    setuptools
    wheel
  ];
  dependencies = with python3Packages; [
    mcp
    httpx
  ];

  # Install exactly the add-on bundled with this server, not a moving main branch.
  postInstall = ''
    install -Dm444 src/blender_mcp/bundled/addon.py \
      $out/share/blender-mcp/blender_mcp.py
  '';

  nativeCheckInputs = [ python3Packages.pytestCheckHook ];
  pytestFlags = [ "tests/test_safe_mode.py" ];
  env.DISABLE_TELEMETRY = "true";
  pythonImportsCheck = [ "blender_mcp.server" ];

  meta = {
    description = "MCP server and companion add-on for controlling Blender";
    homepage = "https://github.com/ahujasid/mcp-for-blender";
    license = lib.licenses.mit;
    mainProgram = "mcp-for-blender";
  };
}
