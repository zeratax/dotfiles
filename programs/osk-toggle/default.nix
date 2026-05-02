{pkgs, config, lib, ...}:
let
  pluginSource = "https://github.com/noctalia-dev/noctalia-plugins";
in
lib.mkIf config.programs.noctalia-shell.enable {
  home.packages = [
    (pkgs.wvkbd.overrideAttrs {
      makeFlags = ["LAYOUT=deskintl"];
      meta.mainProgram = "wvkbd-deskintl";
    })
  ];

  programs.noctalia-shell = {
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
