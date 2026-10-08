{
  config,
  lib,
  ...
}:
lib.mkIf config.programs.noctalia-shell.enable {
  programs.noctalia-shell = {
    plugins.states.tailscale = import ../noctalia/official-plugin.nix;
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
