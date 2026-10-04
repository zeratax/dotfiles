{pkgs, ...}: {
  imports = [
    ./minimalDesktop.nix
    ../programs/firefox
    ../programs/kde-connect
    # game streaming client (host: kaine, moonshine)
    ../programs/moonlight
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
    ];
  };
}
