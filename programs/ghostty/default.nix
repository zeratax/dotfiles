{config, lib, pkgs, ...}: {
  programs.ghostty = {
    enable = true;
    # On non-NixOS hosts, wrap with nixGL so it can acquire an OpenGL context
    # against the system GPU driver. Identity (no-op) on NixOS.
    package = lib.mkIf config.targets.genericLinux.enable (config.lib.nixGL.wrap pkgs.ghostty);
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

  programs.noctalia-shell = lib.mkIf config.programs.noctalia-shell.enable {
    settings = {
      appLauncher.terminalCommand = "ghostty -e";
      templates.activeTemplates = [
        {id = "ghostty"; enabled = true;}
      ];
    };
    pluginSettings.tailscale.terminalCommand = "ghostty";
  };
}
