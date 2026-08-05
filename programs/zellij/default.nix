{pkgs, config, ...}: let
  shell =
    if config.programs.nushell.enable
    then "nu"
    else "bash";
  # Zellij's link plugin opens clicked file paths without a cwd, so editor panes
  # start at "/". Start in the file's own directory instead, which keeps LSP root
  # detection and relative paths working.
  scrollbackEditor = pkgs.writeShellScriptBin "zellij-scrollback-editor" ''
    for arg in "$@"; do
      case "$arg" in
        -* | +*) continue ;;
      esac
      if [ -e "$arg" ]; then
        cd "$(dirname -- "$arg")" || true
        break
      fi
    done

    exec nvim "$@"
  '';
  configFile = pkgs.writeText "zellij-config.kdl" ''
    default_shell "${shell}"
    scrollback_editor "${scrollbackEditor}/bin/zellij-scrollback-editor"
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
