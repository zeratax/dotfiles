{pkgs, ...}: {
  imports = [
    ./desktop.nix
    ../programs/mangohud
    ../programs/mpv
  ];

  home = {
    packages = with pkgs; [
      obs-studio
      parsec-bin
      protontricks
      spotify
      syncplay
      transmission_4-qt
    ];
  };
}
