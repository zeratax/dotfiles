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
  # The hook gets no stdin: fnm's "install it? [y/N]" prompt can't read the
  # terminal while reedline owns it (EIO + panic), so install without asking,
  # and stay quiet where there's no version file and no `default` alias.
  programs.nushell.extraConfig = ''
    ${fnm} env ${envFlags} --json | from json | load-env
    $env.PATH = ($env.PATH | prepend ($env.FNM_MULTISHELL_PATH | path join bin))
    $env.config = ($env.config? | default {})
    $env.config.hooks = ($env.config.hooks? | default {})
    $env.config.hooks.env_change = ($env.config.hooks.env_change? | default {})
    $env.config.hooks.env_change.PWD = (
      $env.config.hooks.env_change.PWD? | default [] | append {|_, _|
        let r = (null | ^${fnm} use --silent-if-unchanged --install-if-missing | complete)
        print -n $r.stdout
        if $r.exit_code != 0 and not ($r.stderr | str contains 'not installable: default') {
          print -en $r.stderr
        }
      }
    )
  '';
}
