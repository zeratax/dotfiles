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
  imports = [
    ./minimal.nix
    ./programs/alacritty
    ./programs/mpv
    ./programs/vscode
    # ./services/syncthing
  ];
  home = {
    packages = with pkgs; [
      # development
      ## IDES
      jetbrains.idea-ultimate

      # games
      parsec-bin
      prismlauncher
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
      firefox
      inkscape
      keepassxc
      maim
      mullvad-vpn
      nextcloud-client
      tectonic
      texlive.combined.scheme-full
      texstudio

      gnome3.gnome-disk-utility
    ];
  };
}
