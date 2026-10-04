{
  pkgs,
  config,
  lib,
  ...
}: {
  home.packages = [
    (pkgs.wvkbd.overrideAttrs (old: {
      makeFlags = ["LAYOUT=deskintl"];
      meta = old.meta // {mainProgram = "wvkbd-deskintl";};
    }))
  ];

  programs.noctalia-shell = lib.mkIf config.programs.noctalia-shell.enable {
    plugins.states.osk-toggle = import ../noctalia/official-plugin.nix;
    pluginSettings.osk-toggle = {
      backend = "wvkbd";
      hideWhenUnavailable = false;
      disableHoverIcon = false;
      wvkbdBin = "wvkbd-deskintl";
    };
  };
}
