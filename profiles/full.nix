{pkgs, ...}: {
  imports = [
    ./desktop.nix
    ./gaming.nix
    ../programs/alacritty
    ../programs/vscode
  ];

  home = {
    packages = with pkgs; [
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
