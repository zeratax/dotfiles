{
  config,
  lib,
  ...
}: let
  inherit (lib.hm.nushell) toNushell;
  home = config.home.homeDirectory;
  profile = config.home.profileDirectory;

  # hm-session-vars.sh values may use $HOME, which is known here. Anything else
  # with a `$` is shell syntax that nushell can't evaluate, so it is left out.
  expandHome = v: builtins.replaceStrings ["\${HOME}" "$HOME"] [home home] (toString v);
  needsShell = lib.hasInfix "$";
  sessionVariables = lib.mapAttrs (_: expandHome) config.home.sessionVariables;
  usable = lib.filterAttrs (_: v: !needsShell v) sessionVariables;
  skipped = lib.attrNames (lib.filterAttrs (_: needsShell) sessionVariables);
in {
  programs.nushell = {
    enable = true;
    extraLogin = ''
      # home.sessionPath in front of the nix profiles, as in hm-session-vars.sh
      $env.PATH = ($env.PATH | split row (char esep) | prepend ${toNushell {} (
        map expandHome config.home.sessionPath
        ++ ["${profile}/bin" "/nix/var/nix/profiles/default/bin"]
      )} | uniq)

      # home.sessionVariables, as in hm-session-vars.sh
      load-env ${toNushell {} usable}
      ${lib.optionalString (skipped != []) "# skipped, they need a shell: ${lib.concatStringsSep " " skipped}"}

      # XDG_DATA_DIRS needs the nix profile share paths (default per XDG spec)
      $env.XDG_DATA_DIRS = ($env.XDG_DATA_DIRS? | default "/usr/local/share:/usr/share" | split row (char esep) | prepend [
        ${toNushell {} "${profile}/share"}
        "/nix/var/nix/profiles/default/share"
      ] | uniq | str join (char esep))
    '';
  };
}
