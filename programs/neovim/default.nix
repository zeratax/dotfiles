{
  pkgs,
  neovim-config,
  ...
}: {
  home.packages = [
    neovim-config.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
