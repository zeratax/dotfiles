{pkgs, config, lib, ...}: {
  home.packages = with pkgs; [
    claude-code
    claude-agent-acp
  ];

  programs.noctalia-shell.plugins.states.claude-code-panel =
    lib.mkIf config.programs.noctalia-shell.enable {
      enabled = true;
      sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
    };
}
