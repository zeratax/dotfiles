{
  pkgs,
  ...
}: let
  pkgsUnstable = import <nixos-unstable> {};
in {
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
      # minecraft # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/pkgs/games/minecraft/default.nix#L156
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
