{userConfig, config, lib, ...}:
let
  pluginSource = "https://github.com/noctalia-dev/noctalia-plugins";
in {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "github.com" = {
        hostname = "github.com";
        user = userConfig.githubUser;
        identityFile = userConfig.sshKeyFile;
      };
      "dmnd.sh dmnd" = {
        hostname = "phantom.dmnd.sh";
        user = "matrix";
        identityFile = userConfig.sshKeyFile;
      };
    };
  };

  programs.noctalia-shell.plugins.states.ssh-sessions =
    lib.mkIf config.programs.noctalia-shell.enable {
      enabled = true;
      sourceUrl = pluginSource;
    };
}
