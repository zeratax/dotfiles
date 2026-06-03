{pkgs, ...}: {
  imports = [
    ./minimalDesktop.nix
    ../programs/mangohud
    ../programs/steam
  ];

  home.packages = with pkgs; [
    protontricks
  ];
}
