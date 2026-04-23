{pkgs, ...}: {
  imports = [
    ./desktop.nix
    ../programs/mangohud
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
