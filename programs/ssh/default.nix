{...}: let
  sshKey = "~/.ssh/id_rsa";
in {
  programs.ssh = {
    enable = true;
    # agentTimeout = "1h";
    matchBlocks = {
      "github.com" = {
        hostname = "github.com";
        user = "ZerataX";
        identityFile = sshKey;
      };
      "dmnd.sh dmnd" = {
        hostname = "phantom.dmnd.sh";
        user = "matrix";
        identityFile = sshKey;
      };
    };
  };
}
