{pkgs, config, ...}: let
  shell =
    if config.programs.nushell.enable
    then "nu"
    else "bash";
  configFile = pkgs.writeText "zellij-config.kdl" ''
    default_shell "${shell}"
    ${builtins.readFile ./config.kdl}
  '';
in {
  home.packages = [pkgs.claude-code];

  xdg.configFile."zellij/config.kdl".source = configFile;
  xdg.configFile."zellij/layouts/default.kdl".source = ./default-layout.kdl;

  programs.bash = {
    shellAliases = {
      zwd = "zellij attach $(echo $(pwd) | sed 's/\\//\\\\/g') -c";
    };
  };

  home.sessionVariables = {ZELLIJ_AUTO_ATTACH = "true";};

  programs.zellij = {
    enable = true;
    enableBashIntegration =
      false; # https://github.com/zellij-org/zellij/issues/2100
  };
}
