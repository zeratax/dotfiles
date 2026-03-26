{userConfig, ...}: {
  programs.ssh = {
    enable = true;
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
}
