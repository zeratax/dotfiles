{config, ...}: {
  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        name = config.programs.git.settings.user.name;
        email = config.programs.git.settings.user.email;
      };
      aliases.bdiff = {
        definition = [
          "util"
          "exec"
          "--"
          "bash"
          "-c"
          ''
            set -euo pipefail
            if [ "$#" -lt 1 ]; then
              echo "usage: jj bdiff <branch> [fileset ...]" >&2
              exit 2
            fi
            branch_rev="$1"
            shift
            exec jj diff \
              --from "fork_point(trunk() | $branch_rev)" \
              --to "$branch_rev" \
              "$@"
          ''
          ""
        ];
        doc = "Show a branch diff from its fork point with the repository trunk";
      };
    };
  };
}
