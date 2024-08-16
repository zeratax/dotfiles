{pkgs, ...}: let
  nixos-unstable = import <nixos-unstable> {};
  neovim-config = import ./neovim-config {};
in {
  programs.neovim = {
    enable = true;
    package = nixos-unstable.neovim-unwrapped;
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
      nodePackages.pyright
      nixos-unstable.ruff-lsp

      # other dependencies
      unzip
      gdb
      gnumake
    ];
    extraLuaConfig = ''
      package.path = package.path .. ";${neovim-config}/?.lua"
      package.path = package.path .. ";${neovim-config}/lua/?.lua"
      require "init"
    '';
    plugins = with pkgs.vimPlugins; [
      telescope-fzf-native-nvim
    ];
  };
}
