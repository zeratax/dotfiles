{
  config,
  lib,
  pkgs,
  ...
}: {
  # vesktop pins pnpm_10_29_2, which nixpkgs marks insecure
  # (CVE-2026-48995/50014-50017/50573/55699). The patched pnpm_10 rejects
  # vesktop's lockfile (same shape as the vue-language-server problem),
  # so allow the insecure pin until upstream regenerates the lockfile.
  nixpkgs.config.permittedInsecurePackages = ["pnpm-10.29.2"];

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
