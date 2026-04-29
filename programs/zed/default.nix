{pkgs, config, lib, ...}: {
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

  programs.noctalia-shell.settings.templates.activeTemplates =
    lib.mkIf config.programs.noctalia-shell.enable [
      {id = "zed"; enabled = true;}
    ];
}
