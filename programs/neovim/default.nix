{ pkgs, ... }:
let
  unstable = import <nixos-unstable> { };
  neovim-config = import ./neovim-config { };
in {
  programs.neovim = {
    enable = true;
    withNodeJs = true;
    withPython3 = true;
    extraPackages = with pkgs; [
      # language servers
      unstable.ruff-lsp
      nodePackages.pyright
      lua-language-server

      # other dependencies
      gdb
    ];
    extraLuaConfig = ''
      dofile("${neovim-config}/init.lua")
    '';
  };
}
