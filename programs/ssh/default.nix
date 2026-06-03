{userConfig, config, lib, ...}:
let
  pluginSource = "https://github.com/noctalia-dev/noctalia-plugins";
in {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "github.com" = {
        HostName = "github.com";
        User = userConfig.githubUser;
        IdentityFile = userConfig.sshKeyFile;
      };
      "dmnd.sh dmnd" = {
        HostName = "phantom.dmnd.sh";
        User = "matrix";
        IdentityFile = userConfig.sshKeyFile;
      };
    };
  };

  programs.noctalia-shell.plugins.states.ssh-sessions =
    lib.mkIf config.programs.noctalia-shell.enable {
      enabled = true;
      sourceUrl = pluginSource;
    };
}
