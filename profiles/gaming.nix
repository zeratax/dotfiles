{pkgs, ...}: {
  imports = [
    ./minimal.nix
    ./minimalDesktop.nix
    ../programs/mangohud
    ../programs/steam
  ];

  home.packages = with pkgs; [
    protontricks # CLI/zenity, no GL of its own
  ];
}
