{userConfig, ...}: {
  programs.git = {
    enable = true;

    signing = {
      signByDefault = userConfig.gpgSignByDefault;
      key = userConfig.gpgSigningKey;
      format = "openpgp";
    };

    # Large File Storage
    lfs.enable = true;

    settings = {
      user = {
        name = userConfig.gitUserName;
        email = userConfig.gitUserEmail;
      };
      core.editor = "vim";
      diff.tool = "vimdiff";
      merge.tool = "vimdiff";
      merge.conflictstyle = "diff3";
    };
  };
}
