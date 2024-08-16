{
  lib,
  config,
  ...
}: {
  programs.direnv = {
    enable = true;
    enableBashIntegration =
      lib.mkIf config.programs.bash.enable
      true;
    nix-direnv.enable = true;
  };
}
