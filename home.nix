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
      nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
        inherit pkgs;
        repoOverrides = {} // lib.optionalAttrs (builtins.pathExists ~/git/nur-packages) {
          zeratax = import ~/git/nur-packages {};
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
    homeDirectory = "/home/${home.username}";
    username = "kaine";

    sessionVariables = {
      MANGOHUD = 1;
    };
    packages = with pkgs; [
      # development
      bat
      cachix
      gcc
      nixfmt
      ## IDES
      jetbrains.idea-ultimate
      # version control
      git-crypt
      gitAndTools.gh

      jq

      # games
      multimc
      obs-studio
      pkgsUnstable.minecraft
      pkgsUnstable.protontricks
      lutris
      steam
      # rpcs3
      xonotic

      # media
      transmission-gtk
      spotify
      # spotify-tui
      pkgsUnstable.syncplay # temporary: https://github.com/NixOS/nixpkgs/pull/102130

      # productivity
      ## social
      # pkgsUnstable.mirage-im # temporary: https://github.com/NixOS/nixpkgs/issues/94905
      nheko
      ## general
      chromium
      evince
      feh
      inkscape
      keepassxc
      maim
      mullvad-vpn
      neofetch
      nextcloud-client
      tectonic
      texlive.combined.scheme-full
      texstudio
      tree
      xclip
      
      gnome3.gnome-disk-utility
    ];
  };

  imports = [
    ./programs/alacritty
    ./programs/bash
    # ./programs/color # vuln in python pillow 2.6
    ./programs/git
    ./programs/gpg
    ./programs/mpv
    ./programs/ssh
    ./programs/vim
    ./programs/vscode
    ./services/syncthing
    ./programs/yaml2nix.nix
  ];

  home.stateVersion = "21.05";
}
