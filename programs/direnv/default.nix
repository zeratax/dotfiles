{ pkgs, lib, config, ... }:

{
  programs.direnv = {
    enable = true;
    enableBashIntegration = lib.mkIf config.programs.bash.enable
      true; # see note on other shells below
    nix-direnv.enable = true;
  };
}
