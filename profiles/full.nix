{pkgs, ...}: {
  imports = [
    ./minimal.nix
    ../programs/alacritty
    ../programs/gpg
    ../programs/mpv
    ../programs/vscode
    # ../services/syncthing
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
      # minecraft  # currently broken
      protontricks
      lutris
      steam
      xonotic

      # media
      transmission-gtk
      spotify
      syncplay

      # productivity
      ## social
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

      gnome.gnome-disk-utility
    ];
  };
}
