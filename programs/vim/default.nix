{ pkgs, lib, config, ... }:

let
  pkgsUnstable = import <nixos-unstable> { };
  vimPlugins = pkgsUnstable.vimPlugins;
  cfg = config.programs.vim;
in {
  programs.vim = {
    enable = true;

    defaultEditor = true;

    extraConfig = ''
      source ${./commands.vim}
      source ${./general.vim}
      source ${./keybindings.vim}
      source ${./plugin-settings.vim}
      source ${./ui.vim}
    '';

    plugins = with vimPlugins; [
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

  home.packages = with pkgs;
    lib.mkIf (builtins.elem vimPlugins.tagbar cfg.plugins) [ ctags ];
}
