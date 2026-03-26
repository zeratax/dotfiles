{
  lib,
  userConfig,
  ...
}: {
  programs.git = {
    enable = true;

    userName = userConfig.gitUserName;
    userEmail = userConfig.gitUserEmail;

    signing = {
      signByDefault = userConfig.gpgSignByDefault;
      key = userConfig.gpgSigningKey;
    };

    # Large File Storage
    lfs.enable = true;

    extraConfig = {
      core = {editor = "vim";};

      diff.tool = "vimdiff";
      merge.tool = "vimdiff";
      merge.conflictstyle = "diff3";
    };
  };
}
