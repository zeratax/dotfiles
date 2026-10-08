{
  pkgs,
  config,
  lib,
  ...
}: {
  home.packages = with pkgs; [
    ffmpeg
    imagemagick
    satty
    tesseract
    wf-recorder
    zbar
  ];

  programs.noctalia-shell.plugins.states.screen-toolkit =
    lib.mkIf config.programs.noctalia-shell.enable (import ../noctalia/official-plugin.nix);
}
