{
  config,
  lib,
  ...
}:
lib.mkIf config.programs.noctalia.enable {
  programs.noctalia.settings = {
    plugins.enabled = [
      "rylos/tailnet"
      # tailnet only receives
      "carlocamacho/taildrop"
    ];
    plugin_settings."rylos/tailnet".taildrop_dir = "${config.home.homeDirectory}/Downloads";
    widget.tailscale = {
      type = "rylos/tailnet:bar";
      show_count = false;
    };
  };
}
