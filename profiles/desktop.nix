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
    ../services/plasma-placeholder-fix
    ../services/storagebox
  ];

  home = {
    packages = with pkgs; [
      # streaming/recording
      obs-studio
      # game streaming client (host: kaine, moonshine)
      moonlight-qt
    ];
  };
}
