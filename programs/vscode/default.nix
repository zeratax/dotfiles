{ config, lib, pkgs, ... }:
{
  programs.vscode = {
    enable = true;

    extensions = with pkgs.vscode-extensions; [
      ### TOOLS
      # eamodio.gitlens
      # ms-vscode.cpptools # https://github.com/NixOS/nixpkgs/issues/35088
      ms-vscode-remote.remote-ssh
      pkgs.nur.repos.zeratax.vscode-extensions.github.copilot

      ## LINTER
      pkgs.nur.repos.zeratax.vscode-extensions.b4dm4n.nixpkgs-fmt
      # pkgs.nur.repos.zeratax.vscode-extensions.hookyqr.beautify

      ### LANGUAGES
      scala-lang.scala
      bbenoist.nix
      vscodevim.vim
      pkgs.nur.repos.zeratax.vscode-extensions.crystal-lang-tools.crystal-lang
    ];
  };
}
