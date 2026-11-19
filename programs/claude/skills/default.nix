# Agent skills: root commands (agent-sudo, ./sudo.nix) and KeePass passwords
# (agent-kp, a CLI plus a user service) ask Jona in Qt dialogs and keep his
# passwords out of the agent's context; vacuula reads the robot vacuum's
# self-hosted server. Only the desktop profile imports all of this; kaine
# imports just ./sudo.nix.
{
  pkgs,
  lib,
  ...
}: let
  # agent-kp's approval dialog, on the Qt kdialog uses. The wrapper puts that
  # Qt's plugins ahead of the session's QT_PLUGIN_PATH (an older Qt's).
  agent-kp-dialog = pkgs.stdenv.mkDerivation {
    name = "agent-kp-dialog";
    src = ./agent-kp-dialog.cpp;
    dontUnpack = true;
    nativeBuildInputs = [pkgs.pkg-config pkgs.qt6.wrapQtAppsHook];
    buildInputs = [pkgs.qt6.qtbase];
    buildPhase = ''
      $CXX -std=c++17 -O2 -fPIC -Wall -o agent-kp-dialog $src \
        $(pkg-config --cflags --libs Qt6Widgets)
    '';
    installPhase = "install -Dm755 agent-kp-dialog $out/bin/agent-kp-dialog";
  };
  agent-kp =
    pkgs.writers.writePython3Bin "agent-kp" {
      libraries = with pkgs.python3Packages; [secretstorage systemd-python];
      flakeIgnore = ["E501"];
    }
    (builtins.replaceStrings ["@dialog@"] ["${agent-kp-dialog}/bin/agent-kp-dialog"]
      (builtins.readFile ./agent-kp.py));
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

  # agent-kp's run and forget go through this service. It holds one D-Bus
  # connection for the whole login, and KeePassXC remembers its confirmation
  # per connection, so Jona allows agent-kp there once instead of on every run.
  # The first connection to the socket starts it; it stops with the session.
  systemd.user.sockets.agent-kp = {
    Unit.Description = "agent-kp: KeePass passwords for agents";
    Socket = {
      ListenStream = "%t/agent-kp.sock";
      SocketMode = "0600";
      Accept = false;
      RemoveOnStop = true;
    };
    Install.WantedBy = ["sockets.target"];
  };
  systemd.user.services.agent-kp = {
    Unit = {
      Description = "agent-kp: KeePass passwords for agents";
      PartOf = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "${agent-kp}/bin/agent-kp serve";
      Restart = "on-failure";
    };
  };

  # KeePassXC is the only Secret Service. KWallet's own daemon (ksecretd) must
  # not claim org.freedesktop.secrets, and kwalletd6 (6.26 is only a frontend
  # over the Secret Service) uses KeePassXC instead of ksecretd, so apps on
  # KWallet's API (Claude desktop, Signal, Vesktop) keep their secrets in
  # KeePassXC and only KeePassXC needs unlocking. MigrateTo3rdParty copies
  # each old .kwl wallet over once (asks for its password, keeps the .kwl);
  # rollback: KSecretD Enabled=true. KeePassXC's side (Settings → Secret
  # Service Integration, plus the exposed group in the database settings)
  # lives in its mutable ini and the database itself.
  home.activation.kwalletNoSecretService = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run ${lib.getExe' pkgs.kdePackages.kconfig "kwriteconfig6"} \
      --file kwalletrc --group org.freedesktop.secrets --key apiEnabled false
    run ${lib.getExe' pkgs.kdePackages.kconfig "kwriteconfig6"} \
      --file kwalletrc --group KSecretD --key Enabled false
    run ${lib.getExe' pkgs.kdePackages.kconfig "kwriteconfig6"} \
      --file kwalletrc --group Migration --key MigrateTo3rdParty true
    # kwalletd6 finds wallets by Secret Service collection label (KeePassXC:
    # the database name) but, while the database is locked at login, falls
    # back to the collection's path name (KeePassXC: the file name, pws) and
    # rewrites Default Wallet with it on every start. Both must be "pws", so
    # the database is named pws too; with a mismatch kwalletd6 asks KeePassXC
    # to create that collection (its "new database" wizard).
    run ${lib.getExe' pkgs.kdePackages.kconfig "kwriteconfig6"} \
      --file kwalletrc --group Wallet --key "Default Wallet" pws
  '';
}
