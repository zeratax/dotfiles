{ pkgs, ... }:
let
  neovim-config = import ./neovim-config { };
in {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    withNodeJs = true;
    withPython3 = true;
    extraPackages = with pkgs; [
      # compilers for plugins
      llvmPackages_17.libcxxClang

      # language servers
      clang-tools
      lua-language-server
      nil
      nixd
      pyright
      ruff

      # other dependencies
      unzip
      gdb
      gnumake
    ];
    extraLuaConfig = ''
      dofile("${neovim-config}/init.lua")
    '';
    plugins = with pkgs.vimPlugins; [
      telescope-fzf-native-nvim
    ];
  };
}
