{
  pkgs,
  config,
  lib,
  ...
}: {
  programs.zed-editor = {
    enable = true;
    # On non-NixOS hosts, wrap with nixGL so it can use the system GPU driver
    # (zed renders through vulkan). Identity (no-op) on NixOS.
    package = lib.mkIf config.targets.genericLinux.enable (config.lib.nixGL.wrap pkgs.zed-editor);
    installRemoteServer = true;
    extraPackages = with pkgs; [
      nil
      nixd
    ];
    extensions = [
      "nix"
    ];
    userSettings = {
      telemetry = {
        metrics = false;
      };
      lsp = {
        nil = {
          binary = {
            path_lookup = true;
          };
        };
        nixd = {
          binary = {
            path_lookup = true;
          };
        };
      };
    };
  };

  home.packages = lib.mkIf config.programs.noctalia.enable [pkgs.sqlite];

  programs.noctalia.settings = lib.mkIf config.programs.noctalia.enable {
    theme.templates.community_ids = ["zed"];
    plugins.enabled = ["cleboost/zed-provider"];
  };
}
