# Node.js version manager. Switches versions on cd from .node-version, .nvmrc or
# package.json#engines.node, looking in parent directories too.
{
  lib,
  pkgs,
  ...
}: let
  fnm = lib.getExe pkgs.fnm;
  envFlags = "--use-on-cd --version-file-strategy=recursive";
in {
  home.packages = [pkgs.fnm];

  programs.bash.initExtra = ''
    eval "$(${fnm} env ${envFlags} --shell bash)"
  '';

  # fnm has no nushell output: load its environment from --json and do what
  # --use-on-cd does in bash, i.e. run `fnm use` whenever the directory changes.
  programs.nushell.extraConfig = ''
    ${fnm} env ${envFlags} --json | from json | load-env
    $env.PATH = ($env.PATH | prepend ($env.FNM_MULTISHELL_PATH | path join bin))
    $env.config = ($env.config? | default {})
    $env.config.hooks = ($env.config.hooks? | default {})
    $env.config.hooks.env_change = ($env.config.hooks.env_change? | default {})
    $env.config.hooks.env_change.PWD = (
      $env.config.hooks.env_change.PWD? | default [] | append {|_, _| ^${fnm} use --silent-if-unchanged}
    )
  '';
}
