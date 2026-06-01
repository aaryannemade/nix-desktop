{ ... }:

let
  workspaceBinds = builtins.concatLists (
    builtins.genList (
      i:
      let
        ws = toString (i + 1);
      in
      [
        "SUPER,${ws},view,${ws}"
        "SUPER+SHIFT,${ws},tag,${ws}"
      ]
    ) 9
  );
in
{
  wayland.windowManager.mango = {
    enable = true;

    settings = {
      bind = [
        "SUPER,Return,spawn,ghostty"
        "SUPER+SHIFT,E,quit"
        "SUPER,Q,killclient"
        "SUPER,F,togglefullscreen"
        "SUPER,R,reload_config"
        "SUPER,Left,focusdir,left"
        "SUPER,Right,focusdir,right"
        "SUPER,Up,focusdir,up"
        "SUPER,Down,focusdir,down"
      ] ++ workspaceBinds;
    };
  };
}
