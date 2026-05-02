{
  pkgs,
  config,
  lib,
  ...
}:
let
  pluginSource = "https://github.com/noctalia-dev/noctalia-plugins";
in {
  home.packages = with pkgs; [
    ffmpeg
    imagemagick
    satty
    tesseract
    wf-recorder
    zbar
  ];

  programs.noctalia-shell.plugins.states.screen-toolkit =
    lib.mkIf config.programs.noctalia-shell.enable {
      enabled = true;
      sourceUrl = pluginSource;
    };
}
