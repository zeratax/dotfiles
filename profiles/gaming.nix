{ pkgs, ... }:
{
  imports = [
    ./minimal.nix
    ../programs/alacritty
    ../programs/gpg
    ../programs/mpv
  ];

  home = {
    packages = with pkgs; [
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
