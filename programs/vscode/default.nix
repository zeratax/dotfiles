{ config, lib, pkgs, ... }:
{
  programs.vscode = {
    enable = true;

    extensions = with pkgs.vscode-extensions; [
      # eamodio.gitlens
      bbenoist.Nix
      # ms-vscode.cpptools # https://github.com/NixOS/nixpkgs/issues/35088
      ms-vscode-remote.remote-ssh
      scala-lang.scala
      vscodevim.vim
      pkgs.nur.repos.zeratax.vscode-extensions.b4dm4n.nixpkgs-fmt
      pkgs.nur.repos.zeratax.vscode-extensions.hookyqr.beautify
      pkgs.nur.repos.zeratax.vscode-extensions.crystal-lang-tools.crystal-lang
    ];
  };
}
