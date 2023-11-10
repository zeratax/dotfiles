{ config, lib, pkgs, ... }: {
  imports = [
    # ./default.nix 
    "${
      fetchTarball
      "https://github.com/nix-community/nixos-vscode-server/tarball/master"
    }/modules/vscode-server/home.nix"
  ];

  # home.file.".vscode-server/server-env-setup".source = ./vscode-remote-wsl-nixos/server-env-setup;

  services.vscode-server.enable = true;
  # services.vscode-server.nodejsPackage = pkgs.nodejs-18_x;
}
