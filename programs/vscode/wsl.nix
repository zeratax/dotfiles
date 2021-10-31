{ config, lib, pkgs, ... }:
{
  # imports = [ ./default.nix ];
  home.file.".vscode-server/server-env-setup".source = ./vscode-remote-wsl-nixos/server-env-setup;
}
