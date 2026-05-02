{pkgs, config, lib, ...}:
let
  pluginSource = "https://github.com/noctalia-dev/noctalia-plugins";
in {
  programs.zed-editor = {
    enable = true;
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
