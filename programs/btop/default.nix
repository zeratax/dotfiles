{config, lib, ...}: {
  programs.btop = {
    enable = true;
    settings.color_theme = lib.mkIf config.programs.noctalia-shell.enable "noctalia";
  };

  programs.noctalia-shell.settings.templates.activeTemplates =
    lib.mkIf config.programs.noctalia-shell.enable [
      {id = "btop"; enabled = true;}
    ];
}
