{
  config,
  lib,
  ...
}: {
  programs.zoxide = {
    enable = true;
    enableBashIntegration = lib.mkIf config.programs.bash.enable true;
  };
}
