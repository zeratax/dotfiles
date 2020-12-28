{ config, pkgs, ... }:

let

  pkgsUnstable = import <nixos-unstable> { };
  pkgsOld = import (builtins.fetchGit {
    name = "nixos-unstable-2020-01-26";
    url = "https://github.com/nixos/nixpkgs-channels/";
    ref = "refs/heads/nixos-unstable";
    rev = "499af6321fdebed6826fb72942196490a74fa6b0";
  }) { };

in rec {
  nixpkgs.config = {
    allowUnfree = true;

    packageOverrides = pkgs: {
      nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
        inherit pkgs;
        repoOverrides = {
          zeratax = import ~/git/nur-packages {};
          ## remote locations are also possible:
          # mic92 = import (builtins.fetchTarball "https://github.com/your-user/nur-packages/archive/master.tar.gz");
        };
      };
    };
  };

  nixpkgs.overlays = [
    # ( import ./overlays/steam.nix )
    # ( import ./overlays/mirage.nix )
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
      clang-tools
      cmake
      gcc
      gnumake
      nixfmt
      nodejs
      openjdk
      pkgsUnstable.cmake-format
      ## python
      pkgsUnstable.pypi2nix
      python37Packages.twine
      python37Packages.setuptools
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
      steam
      lutris
      # rpcs3
      xonotic

      # media
      transmission-gtk
      spotify
      # spotify-tui

      # productivity
      ## video editing
      argyllcms
      displaycal
      ## social
      pkgsUnstable.mirage-im
      # temporary: https://github.com/NixOS/nixpkgs/issues/94905
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
      # syncthingtray
      # pkgsUnstable.syncthing-gtk
      tectonic
      texlive.combined.scheme-full
      texstudio
      tree
      xclip
      
      gnome3.gnome-disk-utility
    ];
  };

  imports = [
    ./programs/bash
    ./programs/git
    ./programs/gpg
    ./programs/mpv
    ./programs/ssh
    ./programs/vim
    ./programs/vscode
  ];

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "20.09";
}
