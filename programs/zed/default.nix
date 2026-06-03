{pkgs, config, lib, ...}:
let
  pluginSource = "https://github.com/noctalia-dev/noctalia-plugins";
in {
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

  home.packages = lib.mkIf config.programs.noctalia-shell.enable [pkgs.sqlite];

  programs.noctalia-shell = lib.mkIf config.programs.noctalia-shell.enable {
    settings.templates.activeTemplates = [
      {id = "zed"; enabled = true;}
    ];
    plugins.states.zed-provider = {
      enabled = true;
      sourceUrl = pluginSource;
    };
  };
}
