{
  description = "Home Manager configuration";

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
      flake = false;
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    nur,
    nixos-vscode-server,
    mpv-prescalers,
    neovim-config,
    ...
  }: let
    # Helper function to create a home configuration
    mkHome = {
      system,
      username,
      hostname,
      modules,
    }:
      home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        extraSpecialArgs = {
          inherit nur nixos-vscode-server mpv-prescalers neovim-config;
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
      # WSL work machine
      "jabdinghoff@LT-JABDINGHOFF" = mkHome {
        system = "x86_64-linux";
        username = "jabdinghoff";
        hostname = "LT-JABDINGHOFF";
        modules = [./profiles/wsl.nix];
      };

      # Personal desktop (example - adjust as needed)
      "zeratax@desktop" = mkHome {
        system = "x86_64-linux";
        username = "zeratax";
        hostname = "desktop";
        modules = [./profiles/full.nix];
      };

      # Minimal profile for any machine
      "minimal" = mkHome {
        system = "x86_64-linux";
        username = builtins.getEnv "USER";
        hostname = "generic";
        modules = [./profiles/minimal.nix];
      };
    };
  };
}
