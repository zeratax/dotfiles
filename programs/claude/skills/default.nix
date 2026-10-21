# Agent skills: root commands (agent-sudo) and KeePass passwords (agent-kp) ask
# Jona through KDE dialogs and keep his passwords out of the agent's context;
# vacuula reads the robot vacuum's self-hosted server. NixOS + Plasma only
# (pkexec from /run/wrappers, kdialog), so only the desktop profile imports this.
{
  pkgs,
  lib,
  ...
}: let
  kdialog = lib.getExe' pkgs.kdePackages.kdialog "kdialog";
  agent-sudo = pkgs.writeShellApplication {
    name = "agent-sudo";
    runtimeInputs = with pkgs; [coreutils kdePackages.kdialog];
    text = builtins.readFile ./agent-sudo.sh;
  };
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
in {
  home.packages = [agent-sudo agent-kp vacuula];

  home.file = {
    ".claude/skills/sudo/SKILL.md".source = ./sudo.md;
    ".claude/skills/keepass/SKILL.md".source = ./keepass.md;
    ".claude/skills/vacuula/SKILL.md".source = ./vacuula.md;
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
