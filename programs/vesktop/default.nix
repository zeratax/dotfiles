{config, lib, ...}: {
  # vesktop pins pnpm_10_29_2, which nixpkgs marks insecure
  # (CVE-2026-48995/50014-50017/50573/55699). The patched pnpm_10 rejects
  # vesktop's lockfile (same shape as the vue-language-server problem),
  # so allow the insecure pin until upstream regenerates the lockfile.
  nixpkgs.config.permittedInsecurePackages = ["pnpm-10.29.2"];

  programs.vesktop = {
    enable = true;
  };

  programs.noctalia-shell.settings.templates.activeTemplates =
    lib.mkIf config.programs.noctalia-shell.enable [
      {id = "discord"; enabled = true;}
    ];
}
