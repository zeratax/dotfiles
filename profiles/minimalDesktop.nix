{pkgs, ...}: {
  # opencode-desktop currently bundles electron-40, which nixpkgs marks EOL/insecure.
  nixpkgs.config.permittedInsecurePackages = ["electron-40.10.5"];

  imports = [
    ./minimal.nix
    ../programs/ghostty
    ../programs/mpv
    ../programs/zed
  ];
  home = {
    packages = with pkgs; [
      keepassxc
      obsidian
      opencode-desktop
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
