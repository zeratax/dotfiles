{ config, lib, pkgs, ... }: 

let

  # pkgsZerataX = import ~/git/nixpkgs { };

in {
 
  programs.vscode = {
    enable = true;

    extensions = with pkgs.vscode-extensions; [ 
      # eamodio.gitlens
      bbenoist.Nix
      # ms-vscode.cpptools # https://github.com/NixOS/nixpkgs/issues/35088
      ms-vscode-remote.remote-ssh
      scala-lang.scala
      pkgs.nur.repos.zeratax.vscode-extensions.b4dm4n.nixpkgs-fmt
      pkgs.nur.repos.zeratax.vscode-extensions.hookyqr.beautify
    ];
  };
}
