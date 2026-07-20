{
  config,
  lib,
  pkgs,
  ...
}: let
  nushellIntegration = pkgs.runCommand "nushell-fzf-integration.nu" {} ''
    ${lib.getExe config.programs.fzf.package} --nushell > "$out"
    substituteInPlace "$out" --replace-warn "str downcase" "str lowercase"
  '';
in {
  programs.fzf = {
    enable = true;
    # fzf 0.74.0 emits the deprecated `str downcase`; generate the same
    # integration below with Nu 0.114's replacement instead.
    enableNushellIntegration = false;
  };

  programs.nushell.extraConfig = ''
    source ${nushellIntegration}
  '';
}
