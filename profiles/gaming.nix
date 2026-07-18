{pkgs, ...}: {
  imports = [
    ./minimalDesktop.nix
    ../programs/mangohud
    ../programs/steam
    ../services/storagebox
  ];

  home.packages = with pkgs; [
    protontricks
  ];
}
