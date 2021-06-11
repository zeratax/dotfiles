{ config, lib, pkgs, ... }: {
  programs.git = with config.programs; {
    enable = true;

    userName = "ZerataX";
    userEmail = "mail@zera.tax";

    signing = {
      signByDefault = true;
      key = gpg.settings.default-key;
    };

    # Large File Storage
    lfs.enable = true;

    extraConfig = {
      core = { editor = "vim"; };

      diff.tool = "vimdiff";
      merge.tool = "vimdiff";
      merge.conflictstyle = "diff3";
    };
  };
}
