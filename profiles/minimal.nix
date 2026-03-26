{
  pkgs,
  nur,
  ...
}: {
  nixpkgs.config = {
    allowUnfree = true;
  };

  nixpkgs.overlays = [
    nur.overlays.default
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  home = {
    sessionVariables = {
      FLAKE = "$HOME/git/dotfiles";
      # ANTHROPIC_API_KEY = builtins.readFile ../secrets/anthropic.key;
    };
    shellAliases = {
      # nh with local neovim-config override for development
      nhl = "nh home switch --override-input neovim-config path:$HOME/git/neovim-config";
    };
    packages = with pkgs; [
      # development
      alejandra
      bat
      cachix
      nh
      nixfmt-rfc-style
      wget
      volta

      # version control
      git-crypt
      gh

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
    ../programs/bash
    ../programs/carapace
    ../programs/direnv
    ../programs/eza
    ../programs/git
    ../programs/neovim
    ../programs/nushell
    ../programs/starship
    ../programs/ssh
    ../programs/tmux
    ../programs/vim
    ../programs/yaml2nix.nix
    ../programs/jujutsu
    ../programs/zellij
    ../programs/zoxide
  ];
}
