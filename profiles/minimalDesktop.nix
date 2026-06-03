{pkgs, ...}: {
  imports = [
    ./minimal.nix
    ../programs/ghostty
    ../programs/mpv
    ../programs/zed
  ];
  home = {
    packages = with pkgs; [
      keepassxc
      signal-desktop

      wl-clipboard

      # media
      spotify
      transmission_4-qt
      syncplay
    ];
  };
}
