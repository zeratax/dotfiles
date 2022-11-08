{ config, pkgs, lib, ... }:
{
    imports = [
        ./minimal.nix
    #    ./programs/vscode/wsl.nix # doesnt seem necessary anymore
    ];
}
