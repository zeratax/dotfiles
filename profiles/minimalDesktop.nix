{pkgs, ...}: {
  imports = [
    ./minimal.nix
    ../programs/ghostty
    ../programs/mpv
    ../programs/zed
    ../services/storagebox
  ];
  home = {
    packages = with pkgs; [
      keepassxc
      obsidian
      # Electron only auto-detects kwallet when XDG_CURRENT_DESKTOP=KDE; under niri it falls back and errors.
      (symlinkJoin {
        name = "signal-desktop";
        paths = [signal-desktop];
        nativeBuildInputs = [makeWrapper];
        postBuild = ''
          wrapProgram $out/bin/signal-desktop \
            --add-flags "--password-store=kwallet6"
        '';
      })

      wl-clipboard

      # media
      spotify
      transmission_4-qt
      syncplay
    ];
  };
}
