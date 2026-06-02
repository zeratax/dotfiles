{
  description = "Home Manager configuration";

  nixConfig = {
    extra-substituters = ["https://noctalia.cachix.org"];
    extra-trusted-public-keys = ["noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur.url = "github:nix-community/NUR";

    nixos-vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mpv-prescalers = {
      url = "github:bjin/mpv-prescalers";
      flake = false;
    };

    neovim-config = {
      url = "github:zeratax/neovim-config";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    jj-starship = {
      url = "github:dmmulroy/jj-starship";
    };

    noctalia-shell = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nirinit = {
      url = "github:amaanq/nirinit";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    nur,
    nixos-vscode-server,
    mpv-prescalers,
    neovim-config,
    jj-starship,
    noctalia-shell,
    nirinit,
    ...
  }: let
    defaultUserConfig = {
      gitUserName = "ZerataX";
      gitUserEmail = "mail@zera.tax";
      gpgSigningKey = "0x8333735E784DF9D4";
      gpgSignByDefault = true;
      sshKeyFile = "~/.ssh/id_rsa";
      githubUser = "ZerataX";
    };

    # Helper function to create a home configuration
    mkHome = {
      system,
      username,
      modules,
      userConfig ? defaultUserConfig,
      hostConfig ? {},
    }:
      home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        extraSpecialArgs = {
          inherit nur nixos-vscode-server mpv-prescalers neovim-config jj-starship noctalia-shell nirinit userConfig hostConfig;
        };
        modules =
          [
            {
              home.username = username;
              home.homeDirectory = "/home/${username}";
              home.stateVersion = "24.05";
            }
          ]
          ++ modules;
      };
  in {
    homeConfigurations = {
      # WSL work machines
      "jabdinghoff@LT-JABDINGHOFF" = mkHome {
        system = "x86_64-linux";
        username = "jabdinghoff";
        modules = [./profiles/wsl.nix];
        userConfig = {
          gitUserName = "Jona Abdinghoff";
          gitUserEmail = "jabdinghoff@lancier-monitoring.de";
          gpgSigningKey = null;
          gpgSignByDefault = false;
          sshKeyFile = "~/.ssh/id_ed25519";
          githubUser = "jabdinghoff";
        };
      };

      "jabdinghoff@sf-jabdinghoff" = mkHome {
        system = "aarch64-linux";
        username = "jabdinghoff";
        modules = [./profiles/wsl.nix];
        userConfig = {
          gitUserName = "Jona Abdinghoff";
          gitUserEmail = "jabdinghoff@lancier-monitoring.de";
          gpgSigningKey = null;
          gpgSignByDefault = false;
          sshKeyFile = "~/.ssh/id_ed25519";
          githubUser = "jabdinghoff";
        };
      };

      "jonaa@kaine" = mkHome {
        system = "x86_64-linux";
        username = "jonaa";
        modules = [./profiles/gaming.nix];
      };

      "jonaa@surface" = mkHome {
        system = "x86_64-linux";
        username = "jonaa";
        modules = [./profiles/desktop.nix];
        hostConfig = {
          lowEndGpu = true;
        };
      };

      # Minimal profile for any machine
      # builtins.getEnv returns "" in pure eval (CI), fall back so the config can still be checked
      "minimal" = let u = builtins.getEnv "USER"; in mkHome {
        system = "x86_64-linux";
        username = if u != "" then u else "user";
        modules = [./profiles/minimal.nix];
      };
    };
  };
}
