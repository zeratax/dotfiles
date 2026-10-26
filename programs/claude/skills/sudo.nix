# agent-sudo: root commands for agents, approved by Jona in a KDE dialog and
# authenticated by polkit. Works on NixOS and on generic Linux hosts (kaine);
# they differ only in where pkexec and friends live, and in the container
# the Claude desktop app puts agents in there (see agent-sudo.sh).
{
  config,
  pkgs,
  lib,
  ...
}: let
  paths =
    if config.targets.genericLinux.enable
    then {
      # /usr/bin first: /usr/local is where stray global installs end up
      rootPath = "/usr/bin:/usr/local/sbin:/usr/local/bin";
      pkexec = "/usr/bin/pkexec";
      systemdRun = "/usr/bin/systemd-run";
      env = "/usr/bin/env";
      # pacman-managed and root-owned, like the store; not /usr/local
      trustedPrefixes = "/nix/store/ /usr/bin/ /usr/lib/";
    }
    else {
      rootPath = "/run/wrappers/bin:/run/current-system/sw/bin";
      pkexec = "/run/wrappers/bin/pkexec";
      systemdRun = "/run/current-system/sw/bin/systemd-run";
      env = "/run/current-system/sw/bin/env";
      # setuid wrappers resolve to /run/wrappers/wrappers.<hash>/
      trustedPrefixes = "/nix/store/ /run/wrappers/";
    };
  agent-sudo = pkgs.writeShellApplication {
    name = "agent-sudo";
    runtimeInputs = with pkgs; [coreutils kdePackages.kdialog];
    text =
      builtins.replaceStrings
      (map (n: "@${n}@") (lib.attrNames paths))
      (lib.attrValues paths)
      (builtins.readFile ./agent-sudo.sh);
  };
in {
  home.packages = [agent-sudo];
  home.file.".claude/skills/sudo/SKILL.md".source = ./sudo.md;
}
