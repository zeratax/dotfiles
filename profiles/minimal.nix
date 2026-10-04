{
  pkgs,
  nur,
  noctalia-shell,
  jj-hunk,
  config,
  llm-agents,
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
    sessionPath = ["$HOME/.cargo/bin"];
    sessionVariables = {
      NH_FLAKE = "${config.home.homeDirectory}/Projects/dotfiles";
      NH_OS_FLAKE = "${config.home.homeDirectory}/Projects/nixos-config";
    };
    shellAliases = {
      # nh with local neovim-config override for development
      nhl = "nh home switch -- --override-input neovim-config path:${config.home.homeDirectory}/Projects/neovim-config";
    };
    packages = with pkgs; [
      # development
      llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex
      alejandra
      cachix
      fh # FlakeHub CLI
      nh
      nil
      nix-search-cli
      nixd
      nixfmt
      llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode2
      wget

      # version control
      gh
      jj-hunk.packages.${pkgs.stdenv.hostPlatform.system}.default # scriptable jj split

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

  # The noctalia home module (option namespace) is imported everywhere so that
  # per-program integrations can reference `programs.noctalia-shell.enable`.
  # Actually enabling/configuring the shell is opt-in per profile via
  # ../programs/noctalia (currently only surface, see desktop.nix).
  imports = [
    noctalia-shell.homeModules.default
    ../programs/bash
    ../programs/bat
    ../programs/btop
    ../programs/carapace
    ../programs/claude
    ../programs/delta
    ../programs/direnv
    ../programs/difft
    ../programs/eza
    ../programs/fnm
    ../programs/fzf
    ../programs/git
    ../programs/gpg
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
