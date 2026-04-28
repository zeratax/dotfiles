{...}: {
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
      theme = "noctalia";
    };
  };
}
