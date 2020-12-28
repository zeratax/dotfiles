{pkgs,  ...}:

{
  programs.bash = {
    enable = true;
    # sessionVariables = home.sessionVariables;
    # https://github.com/rycee/home-manager/issues/1011
    bashrcExtra = ''
      export MANGOHUD=1
    '';
  };
}
