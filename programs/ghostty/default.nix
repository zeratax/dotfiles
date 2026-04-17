{...}: {
  programs.ghostty = {
    enable = true;
    enableBashIntegration = true;
    installVimSyntax = true;
    systemd.enable = true;
  };
}
