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
      # track v4 maintenance branch — main is v5, a breaking rewrite
      # (programs.noctalia-shell → programs.noctalia, plugins/pluginSettings removed,
      # new TOML settings schema). Switch back to main after migrating.
      url = "github:noctalia-dev/noctalia/legacy-v4";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nirinit = {
      url = "github:amaanq/nirinit";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Used on non-NixOS hosts to run Nix graphical apps against the system GPU
    # driver (see profiles/gaming.nix and the "jonaa@kaine" host below).
    nixGL = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nixGL calls `nvidia_x11.override { kernel = null; }`, which our
    # nixpkgs-unstable no longer accepts. Build nixGL against the nixpkgs it was
    # last tested with instead; it only provides the GPU wrapper, so it doesn't
    # need to track our package set.
    nixpkgs-nixgl.url = "github:nixos/nixpkgs/93e8cdce7afc64297cfec447c311470788131cd9";
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
    nixGL,
    nixpkgs-nixgl,
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
        modules = [
          ./profiles/gaming.nix
          ({pkgs, ...}: {
            # kaine runs CachyOS, not NixOS: let home-manager configure
            # graphical apps but use nixGL to run them against the system
            # NVIDIA driver. Vulkan is enabled because mpv (gpu-api=vulkan) and
            # zed render through it.
            targets.genericLinux.enable = true;
            targets.genericLinux.nixGL = {
              # nixGL's auto-detection can't parse the current open-kernel-module
              # version string (nix-community/nixGL#220), so pin nixGL to the
              # driver explicitly. This MUST match the version that is *running*
              # when apps launch, i.e. `pacman -Q nvidia-utils` after a reboot
              # (the userspace libs must match the loaded kernel module). Bump it
              # whenever CachyOS updates the nvidia package.
              packages = import "${nixGL}/default.nix" {
                pkgs = import nixpkgs-nixgl {
                  inherit (pkgs.stdenv.hostPlatform) system;
                  config.allowUnfree = true;
                };
                nvidiaVersion = "610.43.02";
                # Pinning the hash keeps evaluation pure: without it nixGL falls
                # back to `builtins.fetchurl` (no sha256), which fails under the
                # pure flake eval that `nh home switch` uses. Get it with
                # `nix-prefetch-url https://download.nvidia.com/XFree86/Linux-x86_64/<ver>/NVIDIA-Linux-x86_64-<ver>.run`
                # and bump it alongside nvidiaVersion.
                nvidiaHash = "0qvllxnb20arjhw3bxdz0hw521di9ib75hldzx97gpscpdaa0d1h";
              };
              defaultWrapper = "nvidia";
              vulkan.enable = true;
            };
            # The nvidia wrappers require impure evaluation; default it on so
            # `nh home switch` works without passing `-- --impure` every time.
            home.sessionVariables.NIX_CONFIG = "pure-eval = false";
          })
        ];
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
