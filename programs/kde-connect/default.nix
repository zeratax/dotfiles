{
  config,
  lib,
  ...
}: {
  programs.noctalia.settings = lib.mkIf config.programs.noctalia.enable {
    plugins.enabled = ["icefish/phone-connect"];
    widget.phone-connect.type = "icefish/phone-connect:bar";
  };
}
