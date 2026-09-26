# Restart plasmashell after it falls back to a placeholder screen.
#
# On resume kwin's first atomic modesets fail (surface, kwin 6.6.6), so all
# outputs vanish for a moment and plasmashell logs "There are no outputs -
# creating placeholder screen". When DP-1 comes back it never moves the
# desktop/panel containments onto it: no wallpaper, no taskbar. A plasmashell
# restart fixes it, so do that automatically.
{pkgs, ...}: let
  watcher = pkgs.writeShellScript "plasma-placeholder-fix" ''
    ${pkgs.systemd}/bin/journalctl --user -u plasma-plasmashell -f -n0 -o cat \
      | while IFS= read -r line; do
          [[ $line == *"creating placeholder screen"* ]] || continue
          # outputs flap a few times on resume; wait until the log goes quiet
          while IFS= read -r -t 5 _; do :; done
          echo "plasmashell fell back to a placeholder screen, restarting it"
          ${pkgs.systemd}/bin/systemctl --user restart plasma-plasmashell.service
        done
  '';
in {
  systemd.user.services.plasma-placeholder-fix = {
    Unit = {
      Description = "Restart plasmashell when it loses all screens";
      # stop with the session, not with plasmashell (which this unit restarts)
      PartOf = ["plasma-workspace.target"];
    };
    Service = {
      ExecStart = "${watcher}";
      Restart = "on-failure";
    };
    Install.WantedBy = ["plasma-workspace.target"];
  };
}
