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
in {
  home.packages = [pkgs.sshfs];

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
