{pkgs, ...}: {
  imports = [
    ./minimal.nix
    ./minimalDesktop.nix
    ../programs/firefox
    ../programs/gpg
    ../programs/kde-connect
    ../programs/niri
    ../programs/screen-toolkit
    ../programs/tailscale
    ../programs/vesktop
  ];

  home = {
    packages = with pkgs; [
      keepassxc
      wl-clipboard
      signal-desktop

      # media
      spotify
      transmission_4-qt
      syncplay

      # streaming/recording
      obs-studio
    ];
  };
}
