{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.vesktop.enable = true;

  # Chromium opens cameras via V4L2 by default, and on IPU6 laptops (surface)
  # the V4L2 nodes only carry raw Bayer, so no camera shows up. Use the
  # PipeWire camera portal instead. Chromium honours only the last
  # --enable-features, so repeat the one the upstream wrapper already sets.
  # (A plain wrapper can't go in programs.vesktop.package: the HM module calls
  # .override on it, so install it next to it with higher priority.)
  home.packages = [
    (lib.hiPrio (pkgs.symlinkJoin {
      name = "vesktop-pipewire-camera";
      paths = [pkgs.vesktop];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/vesktop \
          --add-flags "--enable-features=WaylandWindowDecorations,WebRtcPipeWireCamera"
      '';
    }))
  ];

  programs.noctalia-shell.settings.templates.activeTemplates = lib.mkIf config.programs.noctalia-shell.enable [
    {
      id = "discord";
      enabled = true;
    }
  ];
}
