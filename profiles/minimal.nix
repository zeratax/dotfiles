{
  pkgs,
  nur,
  noctalia-shell,
  config,
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
      NH_FLAKE = "${config.home.homeDirectory}/git/dotfiles";
      NH_OS_FLAKE = "${config.home.homeDirectory}/git/nixos-config";
    };
    shellAliases = {
      # nh with local neovim-config override for development
      nhl = "nh home switch -- --override-input neovim-config path:${config.home.homeDirectory}/git/neovim-config";
    };
    packages = with pkgs; [
      # development
      alejandra
      cachix
      codex
      nh
      nil
      nix-search-cli
      nixd
      nixfmt
      wget

      # version control
      gh

      jq
      ripgrep

      # productivity
      ## general
      fastfetch
      fd
      tealdeer
      tree
      xclip
    ];
  };

  imports = [
    noctalia-shell.homeModules.default
    ../programs/bash
    ../programs/bat
    ../programs/btop
    ../programs/carapace
    ../programs/claude
    ../programs/direnv
    ../programs/eza
    ../programs/fzf
    ../programs/git
    ../programs/jujutsu
    ../programs/neovim
    ../programs/nushell
    ../programs/ssh
    ../programs/starship
    ../programs/tmux
    ../programs/vim
    ../programs/yaml2nix.nix
    ../programs/zellij
    ../programs/volta
    ../programs/zoxide
  ];
}
