{config, lib, ...}: {
  programs.noctalia-shell.settings.templates.activeTemplates =
    lib.mkIf config.programs.noctalia-shell.enable [
      {id = "steam"; enabled = true;}
    ];
}
