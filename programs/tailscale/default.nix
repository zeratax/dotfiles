{ config, lib, ... }:
let
  pluginSource = "https://github.com/noctalia-dev/noctalia-plugins";
in
lib.mkIf config.programs.noctalia-shell.enable {
  programs.noctalia-shell = {
    plugins.states.tailscale = {
      enabled = true;
      sourceUrl = pluginSource;
    };
    pluginSettings.tailscale = {
      refreshInterval = 5000;
      compactMode = true;
      showIpAddress = false;
      showPeerCount = false;
      hideDisconnected = false;
      hideMullvadExitNodes = true;
      sshUsername = "";
      pingCount = 5;
      defaultPeerAction = "copy-ip";
      taildropEnabled = true;
      taildropDownloadDir = "~/Downloads";
      taildropReceiveMode = "operator";
      loginServer = "";
    };
  };
}
