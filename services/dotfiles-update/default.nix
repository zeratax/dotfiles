# One button for dotfiles updates.
#
# Dependabot keeps an update PR open and CI builds it. Once it's green this
# shows a notification; Apply switches this machine to the merge GitHub would
# produce and merges the PR only if activation worked, so a bad update never
# lands on nixos. Other machines then notice nixos moved and offer the same
# button. Nothing is switched without a press.
{
  config,
  pkgs,
  dotfilesNarHash,
  ...
}: let
  check = pkgs.writeShellApplication {
    name = "dotfiles-update";
    runtimeInputs = with pkgs; [coreutils gh git jujutsu libnotify nh systemd];
    text = ''
      repo=zeratax/dotfiles
      checkout=${config.home.homeDirectory}/Projects/dotfiles
      notify() { notify-send -a dotfiles "$@"; }
      switch() { if command -v nhs >/dev/null; then nhs "$@"; else nh home switch "$@"; fi; }

      # Over HTTPS with gh's token: a user unit has no ssh agent.
      fetch() {
        GIT_CONFIG_COUNT=2 \
          GIT_CONFIG_KEY_0=url.https://github.com/.insteadOf GIT_CONFIG_VALUE_0=git@github.com: \
          GIT_CONFIG_KEY_1=credential.https://github.com.helper GIT_CONFIG_VALUE_1='!gh auth git-credential' \
          jj -R "$checkout" git fetch
      }

      local_work() {
        jj -R "$checkout" log --no-graph -r '(nixos@origin..@) ~ (empty() & description(exact:""))' -T 'change_id.short() ++ "\n"'
      }

      origin_rev() { jj -R "$checkout" log --no-graph -r nixos@origin -T commit_id; }
      nixos_tip() { gh api "repos/$repo/branches/nixos" --jq .commit.sha; }
      failed_services() { systemctl --user list-units --type=service --state=failed --plain --no-legend --full | cut -d' ' -f1 | sort; }

      merge_pr() {
        git clone -q "https://github.com/$repo" "$tmp" &&
          parent=$(git -C "$tmp" rev-parse HEAD) &&
          git -C "$tmp" fetch -q origin "pull/$number/head" &&
          git -C "$tmp" -c user.name=dotfiles-update -c user.email=dotfiles-update@localhost -c commit.gpgsign=false merge -q --no-edit FETCH_HEAD
      }

      # The timer also fires right after resume and before login.
      until systemctl --user -q is-active graphical-session.target; do sleep 60; done
      for _ in {1..20}; do gh api rate_limit >/dev/null 2>&1 && break; sleep 30; done

      fetch

      pr=$(gh pr list -R "$repo" --app dependabot --json number,headRefOid,title,mergeable,statusCheckRollup --jq '
        map(select(.mergeable != "CONFLICTING" and any(.statusCheckRollup[]; .name == "DeterminateCI / success" and .conclusion == "SUCCESS")))
        | first // empty | [.number, .headRefOid, .title] | @tsv')
      IFS=$'\t' read -r number head title <<<"$pr"

      if [ -n "$number" ]; then
        summary="Dotfiles update ready"
        body="#$number $title"
      else
        # Mid-development: don't offer to switch away from it.
        [ -z "$(local_work)" ] || exit 0
        rev=$(origin_rev)
        origin_hash=$(nix eval --raw --impure --expr "(builtins.getFlake \"github:$repo/$rev\").narHash")
        [ "$origin_hash" != "${dotfilesNarHash}" ] || exit 0
        summary="Dotfiles changed on another machine"
        body=$(jj -R "$checkout" log --no-graph -r nixos@origin -T 'description.first_line()')
      fi

      # timeout: notify-send never returns if the notification daemon restarts.
      [ "$(timeout 23h notify-send -a dotfiles -t 82800000 -A apply=Apply "$summary" "$body")" = apply ] || exit 0

      # The notification may have been up for hours; offer the fresh state instead.
      if [ -n "$number" ]; then
        [ "$(gh pr view "$number" -R "$repo" --json state,headRefOid --jq '.state + " " + .headRefOid')" = "OPEN $head" ] || exec "$0"
      else
        fetch
        [ "$(origin_rev)" = "$rev" ] || exec "$0"
        flake="github:$repo/$rev"
      fi

      id=$(notify -p "Applying dotfiles update…" "$body")
      export NIX_CONFIG="accept-flake-config = true"

      # GitHub's test merge can lag behind nixos, so merge here: what gets
      # activated is then exactly what merging the PR will produce.
      if [ -n "$number" ]; then
        tmp=$(mktemp -d)
        trap 'rm -rf "$tmp"' EXIT
        if ! merge_pr; then
          notify -u critical -r "$id" "Dotfiles update failed" "Couldn't merge #$number with nixos, nothing was changed. journalctl --user -u dotfiles-update"
          exit 1
        fi
        flake="git+file://$tmp"
      fi

      before=$(failed_services)
      if ! switch "$flake"; then
        notify -u critical -r "$id" "Dotfiles update failed" "Nothing was merged. journalctl --user -u dotfiles-update"
        exit 1
      fi

      # nh exits 0 even when a restarted service fails; give crashes a moment.
      sleep 10
      broken=$(comm -13 <(echo "$before") <(failed_services))
      if [ -n "$broken" ]; then
        notify -u critical -r "$id" "Dotfiles switched, but services failed" "Nothing was merged: $broken"
        exit 1
      fi

      if [ -n "$number" ]; then
        if [ "$parent" != "$(nixos_tip)" ]; then
          notify -r "$id" "Dotfiles switched, not merged" "nixos moved during the build, #$number will be offered again."
          exit 0
        fi
        if ! gh pr merge "$number" -R "$repo" --merge --match-head-commit "$head"; then
          notify -u critical -r "$id" "Dotfiles switched, merge failed" "#$number is still open. journalctl --user -u dotfiles-update"
          exit 1
        fi
      fi

      # A stale checkout would roll this back on the next manual switch.
      note=""
      if ! { fetch && [ -z "$(local_work)" ] && jj -R "$checkout" new nixos@origin; }; then
        note=" Checkout has local revisions, rebase it onto nixos."
      fi
      notify -r "$id" "Dotfiles updated" "$body.$note"
    '';
  };
in {
  systemd.user.services.dotfiles-update = {
    Unit = {
      Description = "Offer pending dotfiles updates";
      # The switch runs from inside this unit; don't let the activation
      # restart it halfway through.
      X-SwitchMethod = "keep-old";
    };
    Service = {
      Type = "oneshot";
      # nix and, on kaine, nhs come from the machine rather than from this script
      Environment = ["PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/bin"];
      ExecStart = "${check}/bin/dotfiles-update";
    };
  };

  systemd.user.timers.dotfiles-update = {
    Unit.Description = "Check for dotfiles updates";
    Timer = {
      OnCalendar = "09:00";
      RandomizedDelaySec = "5m";
      Persistent = true;
    };
    Install.WantedBy = ["timers.target"];
  };
}
