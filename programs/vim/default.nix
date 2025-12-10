{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.programs.vim;
in {
  programs.vim = {
    enable = true;

    extraConfig = ''
      source ${./commands.vim}
      source ${./general.vim}
      source ${./keybindings.vim}
      source ${./plugin-settings.vim}
      source ${./ui.vim}
    '';

    plugins = with pkgs.vimPlugins; [
      ale
      matchit-zip
      # syntastic
      tagbar
      vim-easy-align
      # vim-clang-format
      vim-indentwise
      vim-nix
      vim-scala
    ];
  };

  home.packages =
    lib.mkIf (builtins.elem pkgs.vimPlugins.tagbar cfg.plugins) [pkgs.ctags];
}
