{ config, inputs, ... }:

{
  imports = [ inputs.skills-hub.homeManagerModules.default ];

  programs.agent-skills = {
    enable = true;
    targets.agents = {
      enable = true;
      dest = "${config.xdg.configHome}/agents/skills";
    };
  };
}
