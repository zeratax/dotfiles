{
  pkgs,
  config,
  lib,
  ...
}: {
  home.packages = with pkgs; [
    ffmpeg
    hyprpicker
    imagemagick
    satty
    tesseract
    wf-recorder
    zbar
  ];

  programs.noctalia.settings = lib.mkIf config.programs.noctalia.enable {
    plugins.enabled = ["alexander/screen-toolkit"];
    widget.screen-toolkit.type = "alexander/screen-toolkit:widget";
  };
}
