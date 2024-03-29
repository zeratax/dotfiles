{ config, pkgs, lib, ... }:

let

  pkgsUnstable = import <nixos-unstable> { };
  # pkgsOld = import (builtins.fetchGit {
  #   name = "nixos-unstable-2020-01-26";
  #   url = "https://github.com/nixos/nixpkgs-channels/";
  #   ref = "refs/heads/nixos-unstable";
  #   rev = "499af6321fdebed6826fb72942196490a74fa6b0";
  # }) { };

in rec {
  nixpkgs.config = {
    allowUnfree = true;

    packageOverrides = pkgs: {
      nur = import (builtins.fetchTarball
        "https://github.com/nix-community/NUR/archive/master.tar.gz") {
          inherit pkgs;
          repoOverrides = { }
            // lib.optionalAttrs (builtins.pathExists ~/git/nur-packages) {
              zeratax = import ~/git/nur-packages { };
            };
        };
    };
  };

  nixpkgs.overlays = [
    # (self: super: {
    #   mpv = pkgsOld.mpv;
    # })
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  home = {
    packages = with pkgs; [
      # development
      bat
      cachix
      nixfmt
      wget

      # version control
      git-crypt
      gitAndTools.gh

      jq
      ripgrep

      # productivity
      ## general
      neofetch
      tree
      xclip

      ## networking
      tailscale
    ];
  };

  imports = [
    ./programs/bash
    ./programs/direnv
    ./programs/git
    ./programs/gpg
    ./programs/neovim
    ./programs/oh-my-posh
    ./programs/ssh
    ./programs/tmux
    ./programs/vim
    ./programs/yaml2nix.nix
    ./programs/zellij
  ];
}
