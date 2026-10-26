# Agent skills: root commands (agent-sudo, ./sudo.nix) and KeePass passwords
# (agent-kp) ask Jona through KDE dialogs and keep his passwords out of the
# agent's context; vacuula reads the robot vacuum's self-hosted server. Only the
# desktop profile imports all of this; kaine imports just ./sudo.nix.
{
  pkgs,
  lib,
  ...
}: let
  kdialog = lib.getExe' pkgs.kdePackages.kdialog "kdialog";
  agent-kp =
    pkgs.writers.writePython3Bin "agent-kp" {
      libraries = [pkgs.python3Packages.secretstorage];
      flakeIgnore = ["E501"];
    }
    (builtins.replaceStrings ["@kdialog@"] [kdialog] (builtins.readFile ./agent-kp.py));
  # read-only CLI for the Neato's self-hosted Vacuula server (on homeassistant)
  vacuula =
    pkgs.writers.writePython3Bin "vacuula" {
      libraries = [pkgs.python3Packages.pillow];
      flakeIgnore = ["E501"];
    }
    (builtins.readFile ./vacuula.py);
  # known-WLAN-device lists (MAC filter) on all FRITZ! APs at once
  fritz-wlan =
    pkgs.writers.writePython3Bin "fritz-wlan" {
      libraries = [pkgs.python3Packages.fritzconnection];
      flakeIgnore = ["E501"];
    }
    (builtins.readFile ./fritz-wlan.py);
in {
  imports = [./sudo.nix];

  home.packages = [agent-kp vacuula fritz-wlan];

  home.file = {
    ".claude/skills/keepass/SKILL.md".source = ./keepass.md;
    ".claude/skills/vacuula/SKILL.md".source = ./vacuula.md;
    ".claude/skills/fritz-wlan/SKILL.md".source = ./fritz-wlan.md;
  };

  # agent-kp talks to KeePassXC over the Secret Service API, so KWallet must not
  # claim org.freedesktop.secrets. Apps that use KWallet's own API (Signal and
  # Vesktop via --password-store=kwallet6) are unaffected. KeePassXC's side
  # (Settings → Secret Service Integration, plus the exposed group in the
  # database settings) lives in its mutable ini and the database itself.
  home.activation.kwalletNoSecretService = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run ${lib.getExe' pkgs.kdePackages.kconfig "kwriteconfig6"} \
      --file kwalletrc --group org.freedesktop.secrets --key apiEnabled false
  '';
}
