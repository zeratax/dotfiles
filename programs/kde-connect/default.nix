{config, lib, ...}:
let
  pluginSource = "https://github.com/noctalia-dev/noctalia-plugins";
in {
  programs.noctalia-shell.plugins.states.kde-connect =
    lib.mkIf config.programs.noctalia-shell.enable {
      enabled = true;
      sourceUrl = pluginSource;
    };
}
