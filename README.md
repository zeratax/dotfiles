# Dotfiles
my personal dotfiles managed via [Home Manager](https://github.com/rycee/home-manager)

## setup
0. import ssh key
1. git clone git@github.com/ZerataX/dotfiles ~/git
2. possible configs are `full`, `minimal`, `wsl`
    - ln -sf ~/git/dotfiles/<config>.nix ~/.config/nixpkgs/home.nix
2. install home-manager
3. setup syncthing for ~/sync
4. import gpg key
