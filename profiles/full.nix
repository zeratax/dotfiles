{pkgs, ...}: {
  imports = [
    ./gaming.nix
    ../programs/alacritty
    ../programs/vscode
  ];

  home = {
    packages = with pkgs; [
      # games
      prismlauncher
      protontricks
      lutris
      steam
      xonotic

      # media
      transmission-gtk

      # productivity
      chromium
      evince
      feh
      inkscape
      maim
      mullvad-vpn
      # nextcloud-client
      tectonic
      texlive.combined.scheme-full
      texstudio

      gnome.gnome-disk-utility
    ];
  };
}
