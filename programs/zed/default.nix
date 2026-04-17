{pkgs, ...}: {
  programs.zed-editor = {
    enable = true;
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
}
