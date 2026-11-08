{
  config,
  lib,
  ...
}: {
  programs.btop = {
    enable = true;
    settings.color_theme = lib.mkIf config.programs.noctalia.enable "noctalia";
  };

  programs.noctalia.settings.theme.templates.builtin_ids = lib.mkIf config.programs.noctalia.enable ["btop"];
}
