# Hetzner storage box: sshfs mount of the keepass share at ~/mnt/keepass.
#
# One-time setup per machine (prompts for the subaccount password):
#   ssh-copy-id -p 23 -s u628131-sub1@u628131.your-storagebox.de
#
# The subaccount is chrooted to its basedir (/keepass on the box), which its
# SFTP session exposes as "/home" ("/" itself is not readable). KeePassXC
# opens ~/mnt/keepass/pws.kdbx directly; the keyfile stays local-only in
# ~/Keys (second factor — never on the box).
{
  config,
  pkgs,
  ...
}: let
  remote = "u628131-sub1@u628131.your-storagebox.de";
  mountDir = "${config.home.homeDirectory}/mnt/keepass";
  db = "${mountDir}/pws.kdbx";
  # read-only copy for logins without the mount: KeePassXC must always have
  # a database open, or Secret Service clients (Zed, KWallet) find no
  # collection and KeePassXC answers with its "create database" wizard
  mirror = "${config.home.homeDirectory}/.local/share/keepassxc-mirror/pws.kdbx";

  mirror-update = pkgs.writeShellApplication {
    name = "keepass-mirror-update";
    runtimeInputs = with pkgs; [coreutils util-linux];
    text = ''
      mountpoint -q ${mountDir} && [ -s ${db} ] || exit 0
      mkdir -p "$(dirname ${mirror})"
      tmp=$(mktemp "${mirror}.XXXXXX")
      trap 'rm -f "$tmp"' EXIT
      cp ${db} "$tmp"
      # only a KeePass 2 file (magic 03 d9 a2 9a) replaces the mirror
      [ "$(head -c4 "$tmp" | od -An -tx1 | tr -d ' ')" = 03d9a29a ] || exit 1
      chmod 0444 "$tmp"
      mv -f "$tmp" ${mirror}
    '';
  };

  # waits up to 30 s for the mount (DNS is often late at login), then opens
  # the real database, else the mirror (read-only, so nothing diverges)
  keepassxc-start = pkgs.writeShellApplication {
    name = "keepassxc-start";
    runtimeInputs = with pkgs; [coreutils util-linux gnused];
    text = ''
      path=${mirror}
      for _ in $(seq 30); do
        if mountpoint -q ${mountDir} && [ -s ${db} ]; then path=${db}; break; fi
        sleep 1
      done
      # KeePassXC reopens every previously open database that still exists;
      # make that exactly this one, so the mirror never opens next to it
      ini=''${XDG_CACHE_HOME:-$HOME/.cache}/keepassxc/keepassxc.ini
      if [ -f "$ini" ]; then
        sed -i -e "s|^LastOpenedDatabases=.*|LastOpenedDatabases=$path|" \
          -e "s|^LastActiveDatabase=.*|LastActiveDatabase=$path|" "$ini"
      fi
      exec keepassxc "$path"
    '';
  };
in {
  home.packages = [pkgs.sshfs];

  # replaces the autostart file KeePassXC writes for "Launch at system
  # startup" (leave that setting alone, it would try to rewrite this)
  xdg.configFile."autostart/org.keepassxc.KeePassXC.desktop" = {
    force = true;
    text = ''
      [Desktop Entry]
      Name=KeePassXC
      Exec=${keepassxc-start}/bin/keepassxc-start
      Icon=keepassxc
      Type=Application
      StartupNotify=false
      Terminal=false
      X-GNOME-Autostart-enabled=true
      X-KDE-autostart-after=panel
    '';
  };

  systemd.user.services.keepass-mirror = {
    Unit.Description = "Refresh the read-only local KeePass mirror";
    Service = {
      Type = "oneshot";
      ExecStart = "${mirror-update}/bin/keepass-mirror-update";
    };
  };
  systemd.user.timers.keepass-mirror = {
    Unit.Description = "Refresh the read-only local KeePass mirror";
    Timer = {
      OnStartupSec = "1min";
      OnUnitActiveSec = "10min";
    };
    Install.WantedBy = ["timers.target"];
  };
  # local saves go through the FUSE mount, so inotify sees them
  systemd.user.paths.keepass-mirror = {
    Unit.Description = "Refresh the KeePass mirror when the database is saved";
    Path.PathChanged = db;
    Install.WantedBy = ["paths.target"];
  };

  systemd.user.services.storagebox-keepass = {
    Unit.Description = "sshfs mount of the Hetzner storage box (keepass sync)";
    Service = {
      Type = "exec";
      # sshfs needs the host's setuid fusermount3: /run/wrappers/bin on
      # NixOS (surface), /usr/bin on CachyOS (kaine, fuse3 package).
      Environment = "PATH=/run/wrappers/bin:/run/current-system/sw/bin:/usr/bin:/bin";
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${mountDir}";
      ExecStart = "${pkgs.sshfs}/bin/sshfs -f -p 23 -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,idmap=user,StrictHostKeyChecking=accept-new ${remote}:/home ${mountDir}";
      ExecStop = "/bin/sh -c 'fusermount3 -u ${mountDir} 2>/dev/null || fusermount -u ${mountDir}'";
      # no network-online.target in the user manager; just retry until the
      # network is up
      Restart = "on-failure";
      RestartSec = 15;
    };
    Install.WantedBy = ["default.target"];
  };
}
