{
  pkgs,
  llm-agents,
  ...
}: {
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
      llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-desktop
      llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode2-desktop
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
