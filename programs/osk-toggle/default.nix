{
  pkgs,
  config,
  lib,
  ...
}:
let
  pluginSource = "https://github.com/noctalia-dev/noctalia-plugins";
in {
  home.packages = [
    (pkgs.wvkbd.overrideAttrs {
      makeFlags = ["LAYOUT=deskintl"];
      meta.mainProgram = "wvkbd-deskintl";
    })
  ];

  programs.noctalia-shell = lib.mkIf config.programs.noctalia-shell.enable {
    plugins.states.osk-toggle = {
      enabled = true;
      sourceUrl = pluginSource;
    };
    pluginSettings.osk-toggle = {
      backend = "wvkbd";
      hideWhenUnavailable = false;
      disableHoverIcon = false;
      wvkbdBin = "wvkbd-deskintl";
    };
  };
}
