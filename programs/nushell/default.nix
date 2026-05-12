{config, ...}: {
  programs.nushell = {
    enable = true;
    extraLogin = ''
      if ($env.PATH | split row (char esep) | where $it == $"($env.HOME)/.nix-profile/bin" | is-empty) {
        $env.PATH = ($env.PATH | split row (char esep) | prepend [
          $"($env.HOME)/.nix-profile/bin"
          "/nix/var/nix/profiles/default/bin"
        ])
      }

      ${
        let
          nuPaths = map (p: builtins.replaceStrings ["$HOME"] ["($env.HOME)"] p) config.home.sessionPath;
        in
        if nuPaths == [] then ""
        else ''
          $env.PATH = ($env.PATH | split row (char esep) | prepend [
            ${builtins.concatStringsSep "\n    " (map (p: "$\"${p}\"") nuPaths)}
          ] | str join (char esep))
        ''
      }

      # Session variables from home.sessionVariables (mirrors hm-session-vars.sh)
      ${builtins.concatStringsSep "\n" (
        builtins.attrValues (builtins.mapAttrs
          (name: value:
            let
              strVal = toString value;
              # Replace $HOME with nushell equivalent
              nuVal = builtins.replaceStrings ["$HOME"] ["($env.HOME)"] strVal;
            in
            # Skip values with remaining shell expressions
            if builtins.match ".*\\$\\{.*" nuVal != null
            then "# ${name} skipped: contains shell expression"
            else "$env.${name} = $\"${nuVal}\""
          )
          config.home.sessionVariables
        )
      )}

      # XDG_DATA_DIRS needs nix profile share paths
      $env.XDG_DATA_DIRS = ($env.XDG_DATA_DIRS? | default "" | split row (char esep) | prepend [
        $"($env.HOME)/.nix-profile/share"
        "/nix/var/nix/profiles/default/share"
      ] | str join (char esep))
    '';
  };
}
