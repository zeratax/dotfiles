{
  config,
  lib,
  ...
}: {
  programs.noctalia.settings.theme.templates.community_ids = lib.mkIf config.programs.noctalia.enable ["steam"];
}
