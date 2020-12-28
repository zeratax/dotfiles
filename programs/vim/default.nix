{ pkgs, ... }:

let

  pkgsUnstable = import <nixos-unstable> { };

in {
  programs.vim = {
    enable = true;

    extraConfig = (builtins.readFile ./commands.vim)
      + (builtins.readFile ./general.vim)
      + (builtins.readFile ./keybindings.vim)
      + (builtins.readFile ./plugin-settings.vim)
      + (builtins.readFile ./ui.vim);

    plugins = with pkgs.vimPlugins;
      with pkgsUnstable.vimPlugins; [
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
}
