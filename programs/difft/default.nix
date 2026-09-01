{
  config,
  lib,
  ...
}: {
  programs.difftastic.enable = true;

  programs.git.settings.alias.dft = lib.mkIf config.programs.git.enable "-c diff.external=difft diff";

  programs.jujutsu.settings.aliases.dft = lib.mkIf config.programs.jujutsu.enable [
    "diff"
    "--tool"
    "difft"
  ];
}
