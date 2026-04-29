{config, lib, ...}: {
  programs.ghostty = {
    enable = true;
    enableBashIntegration = true;
    installVimSyntax = true;
    systemd.enable = true;
    settings = {
      keybind = "global:f12=toggle_quick_terminal";
      quick-terminal-position = "top";
      quick-terminal-animation-duration = 0;
      background-opacity = 0.85;
      theme = lib.mkIf config.programs.noctalia-shell.enable "noctalia";
    };
  };

  programs.noctalia-shell.settings = lib.mkIf config.programs.noctalia-shell.enable {
    appLauncher.terminalCommand = "ghostty -e";
    templates.activeTemplates = [
      {id = "ghostty"; enabled = true;}
    ];
  };
}
