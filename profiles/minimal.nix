{
  pkgs,
  nur,
  config,
  ...
}:
{
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
      claude-code
      cachix
      nh
      nil
      nix-search-cli
      nixd
      nixfmt
      volta
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

      ## networking
      tailscale
    ];
  };

  imports = [
    ../programs/bash
    ../programs/bat
    ../programs/btop
    ../programs/carapace
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
    ../programs/zoxide
  ];
}
