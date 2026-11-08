{
  pkgs,
  config,
  lib,
  ...
}: let
  wvkbd = pkgs.wvkbd.overrideAttrs (old: {
    makeFlags = ["LAYOUT=deskintl"];
    meta = old.meta // {mainProgram = "wvkbd-deskintl";};
  });
in {
  home.packages = [wvkbd];

  # Stays running hidden: the bar button and niri's tablet-mode switch only signal it.
  systemd.user.services.wvkbd = lib.mkIf config.programs.noctalia.enable {
    Unit = {
      Description = "On-screen keyboard";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };
    Service = {
      Restart = "on-failure";
      ExecStart = "${lib.getExe wvkbd} --hidden";
    };
    Install = {
      WantedBy = ["graphical-session.target"];
    };
  };

  programs.noctalia.settings.widget.osk-toggle = lib.mkIf config.programs.noctalia.enable {
    type = "custom_button";
    glyph = "keyboard";
    tooltip = "On-screen keyboard";
    actions.left = "exec pkill -RTMIN ${wvkbd.meta.mainProgram}";
  };
}
