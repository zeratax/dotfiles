{
  lib,
  pkgs,
  ...
}: {
  nixpkgs.config = {
    allowUnfree = true;

    packageOverrides = pkgs: {
      nur = import (builtins.fetchTarball
        "https://github.com/nix-community/NUR/archive/master.tar.gz") {
        inherit pkgs;
        repoOverrides =
          {}
          // lib.optionalAttrs (builtins.pathExists ~/git/nur-packages) {
            zeratax = import ~/git/nur-packages {};
          };
      };
    };
  };

  nixpkgs.overlays = [
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  home = {
    packages = with pkgs; [
      # development
      alejandra
      bat
      cachix
      nixfmt-rfc-style
      wget

      # version control
      git-crypt
      gitAndTools.gh

      jq
      ripgrep

      # productivity
      ## general
      neofetch
      tree
      xclip

      ## networking
      tailscale
    ];
  };

  imports = [
    ./programs/bash
    ./programs/direnv
    ./programs/git
    ./programs/gpg
    ./programs/neovim
    ./programs/oh-my-posh
    ./programs/ssh
    ./programs/tmux
    ./programs/vim
    ./programs/yaml2nix.nix
    ./programs/zellij
    ./programs/zoxide
  ];
}
