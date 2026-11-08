{
  config,
  lib,
  ...
}: {
  programs.firefox = {
    enable = true;
    configPath = ".mozilla/firefox";
  };

  # noctalia is the extension's native-messaging host and writes the manifest itself
  programs.noctalia.settings.theme.templates.community_ids = lib.mkIf config.programs.noctalia.enable ["pywalfox"];
}
