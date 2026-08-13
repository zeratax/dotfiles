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
      aliases."move-to" = {
        definition = [
          "util"
          "exec"
          "--"
          "bash"
          "-c"
          ''
            cd "''${JJ_WORKSPACE_ROOT:-.}"
            revset="$1"
            shift
            edit=$(jj config get ui.movement.edit 2>/dev/null || echo false)
            args=()
            for a in "$@"; do
              case $a in
                -e|--edit)    edit=true ;;
                -n|--no-edit) edit=false ;;
                *)            args+=("$a") ;;
              esac
            done
            if $edit; then verb=edit; else verb=new; fi
            exec jj "$verb" "''${args[@]}" "$revset"
          ''
          "jj-move"
        ];
        doc = "Move to a revset: new child of it, or edit it with -e";
      };
      aliases.bottom = {
        definition = [
          "move-to"
          "stack_bottom()"
        ];
        doc = "Move to the bottom of the current stack, stack_bottom()";
      };
      aliases.top = {
        definition = [
          "move-to"
          "stack_top()"
        ];
        doc = "Move to the top of the current stack, stack_top()";
      };
      aliases.sb = {
        definition = [
          "stack-bookmarks"
        ];
        doc = "Shorthand for stack-bookmarks";
      };
      aliases.stack-bookmarks = {
        definition = [
          "--config"
          "revsets.log=substack()"
          "log"
          "--no-graph"
          "--reversed"
          "-T"
          ''if(local_bookmarks, local_bookmarks.map(|b| b.name()).join(" ") ++ " ", "")''
        ];
        doc = "Local bookmark names in substack(@), oldest first, space-separated";
      };
      "revset-aliases"."stack_heads()" = {
        definition = "stack_heads(@)";
        doc = "Newest mutable commits at or ahead of the working copy";
      };
      "revset-aliases"."stack_heads(to)" = {
        definition = "heads(mutable() & to::)";
        doc = "Newest mutable commits at or ahead of to";
      };
      "revset-aliases"."stack_top()" = {
        definition = "stack_top(@)";
        doc = "Newest mutable, single commit at or ahead of the working copy";
      };
      "revset-aliases"."stack_top(to)" = {
        definition = "exactly(stack_heads(to), 1)";
        doc = "Newest mutable, single commit at or ahead of to";
      };
      "revset-aliases"."stack_bottom(to)" = {
        definition = "roots(mutable() & ::to)";
        doc = "Oldest mutable commits at or behind to";
      };
      "revset-aliases"."stack_bottom()" = {
        definition = "stack_bottom(@)";
        doc = "Oldest mutable commits at or behind the working copy";
      };
      "revset-aliases"."stack(to)" = {
        definition = "stack_bottom(to)::stack_top(to)";
        doc = "Full stack containing to, from stack_bottom(to) to stack_top(to)";
      };
      "revset-aliases"."stack()" = {
        definition = "stack(@)";
        doc = "Full stack containing the working copy, from its bottom to its top";
      };
      "revset-aliases"."substack(to)" = {
        definition = "stack_bottom(to)::to";
        doc = "Stack containing to, from stack_bottom(to) through to";
      };
      "revset-aliases"."substack()" = {
        definition = "substack(@)";
        doc = "Stack from its bottom through the working copy";
      };
      "revset-aliases"."tree()" = {
        definition = "tree(@)";
        doc = "Full tree (all stacks) containing the working copy";
      };
      "revset-aliases"."tree(to)" = {
        definition = "reachable(to, mutable())";
        doc = "Full tree (all stacks) containing to";
      };
      "revset-aliases"."closest_pushable(to)" = {
        definition = ''heads(::to & mutable() & ~empty() & description(regex:".+"))'';
        doc = "Closest mutable, non-empty, described commits at or behind to";
      };
      revsets."bookmark-advance-to" = "closest_pushable(@)";
    };
  };
}
