{
  config,
  lib,
  ...
}: {
  programs.noctalia-shell.plugins.states.kde-connect =
    lib.mkIf config.programs.noctalia-shell.enable (import ../noctalia/official-plugin.nix);
}
