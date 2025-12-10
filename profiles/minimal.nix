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
    # sessionVariables = {
    #   ANTHROPIC_API_KEY = builtins.readFile ../secrets/anthropic.key;
    # };
    packages = with pkgs; [
      # development
      alejandra
      bat
      cachix
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
    ../programs/direnv
    ../programs/git
    ../programs/neovim
    ../programs/oh-my-posh
    ../programs/ssh
    ../programs/tmux
    ../programs/vim
    ../programs/yaml2nix.nix
    ../programs/jujutsu
    ../programs/zellij
    ../programs/zoxide
  ];
}
