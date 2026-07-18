{pkgs, ...}: {
  imports = [
    ./minimalDesktop.nix
    ../programs/firefox
    ../programs/kde-connect
    ../programs/niri
    ../programs/noctalia
    ../programs/screen-toolkit
    ../programs/tailscale
    ../programs/vesktop
    ../services/storagebox
  ];

  home = {
    packages = with pkgs; [
      # streaming/recording
      obs-studio
    ];
  };
}
