{ pkgs, ... }:
{
  imports = [
    ./minimal.nix
    ../programs/alacritty
    ../programs/gpg
    ../programs/mangohud
    ../programs/mpv
  ];

  home = {
    packages = with pkgs; [
      # games
      obs-studio
      parsec-bin
      protontricks

      # media
      transmission_4-qt
      spotify
      syncplay

      # productivity
      ## general
      firefox
      keepassxc
    ];
  };
}
