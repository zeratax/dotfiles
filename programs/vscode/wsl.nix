{ config, lib, pkgs, ... }:
{
  imports = [ 
    # ./default.nix 
    (fetchTarball "https://github.com/msteen/nixos-vscode-server/tarball/master")
  ];

  # home.file.".vscode-server/server-env-setup".source = ./vscode-remote-wsl-nixos/server-env-setup;

  services.vscode-server.enable = true;
  services.vscode-server.nodejsPackage = pkgs.nodejs-16_x;
}
