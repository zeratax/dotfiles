{
  description = "Home Manager configuration";

  nixConfig = {
    extra-substituters = [
      "https://noctalia.cachix.org"
      "https://cache.numtide.com"
    ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur.url = "github:nix-community/NUR";

    systems.url = "github:nix-systems/default-linux";

    nixos-vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
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

    # Scriptable file/hunk-level `jj split` (not in nixpkgs).
    jj-hunk = {
      url = "github:laulauland/jj-hunk";
      inputs.nixpkgs.follows = "nixpkgs";
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

    # Nix packaging for LLM agent tooling (claude-desktop & friends). Deliberately
    # no `nixpkgs.follows`: it pins its own nixpkgs for the bun2nix-based FODs, and
    # overriding that invalidates their recorded hashes.
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
    };

    # Used on non-NixOS hosts to run Nix graphical apps against the system GPU
    # driver (see profiles/gaming.nix and the "jonaa@kaine" host below).
    # Patched at eval time — see ./patches/nixgl-*.patch.
    nixGL = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nixGL must be built against this old nixpkgs, not ours. Current nixpkgs'
    # nvidia-x11 builder deletes the driver's prebuilt EGL platform libraries
    # (`rm -f $i/lib/libnvidia-egl-*  # built from source`) and stops installing
    # share/egl/egl_external_platform.d, because NixOS supplies them from
    # separate source-built packages instead. nixGL doesn't put those back, so a
    # nixGL built against current nixpkgs has no libnvidia-egl-wayland/-gbm and
    # every GTK app dies on Wayland with "Failed to create EGL display" — GLX
    # keeps working, which makes it look like GL is fine. This pin is the last
    # nixpkgs that still ships them. nixGL only provides the GPU wrapper, so it
    # doesn't need to track our package set.
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
    jj-hunk,
    noctalia-shell,
    nirinit,
    llm-agents,
    nixGL,
    nixpkgs-nixgl,
    systems,
    ...
  }: let
    supportedSystems = import systems;
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

    defaultUserConfig = {
      gitUserName = "ZerataX";
      gitUserEmail = "contact@zera.tax";
      gpgSigningKey = null;
      gpgSignByDefault = false;
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
          inherit nur nixos-vscode-server mpv-prescalers neovim-config jj-starship jj-hunk noctalia-shell nirinit llm-agents userConfig hostConfig;
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
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

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
        userConfig =
          defaultUserConfig
          // {
            # GitHub rejects the RSA key; kaine authenticates with ed25519.
            sshKeyFile = "~/.ssh/id_ed25519";
          };
        modules = [
          ./profiles/gaming.nix
          ({
            pkgs,
            lib,
            config,
            ...
          }: let
            nixglPkgs = import nixpkgs-nixgl {
              inherit (pkgs.stdenv.hostPlatform) system;
              config.allowUnfree = true;
            };

            # nixGL's driver auto-detection regex only matches the proprietary
            # kernel module's version banner ("Kernel Module  610.57.04  "), not
            # the open module's ("...Open Kernel Module for x86_64  610.57.04  "),
            # so on kaine it silently fell back to Mesa
            # (nix-community/nixGL#220). Drop this once the PR lands upstream.
            #
            # Note nixGL#222 fixes the same bug but its regex stops matching the
            # old proprietary banner; #221's handles both.
            nixGLPatched = nixglPkgs.applyPatches {
              name = "nixGL-patched";
              src = nixGL;
              patches = [./patches/nixgl-pr221-open-module-version.patch];
            };

            # Pure evaluation cannot inspect the host driver, so use a
            # deterministic driver artifact there. Impure evaluations leave
            # both values unset and let nixGL detect the running driver.
            nixGLPackageArgs =
              {
                pkgs = nixglPkgs;
              }
              // lib.optionalAttrs (!(builtins ? currentTime)) {
                nvidiaVersion = "610.43.02";
                nvidiaHash = "0qvllxnb20arjhw3bxdz0hw521di9ib75hldzx97gpscpdaa0d1h";
              };
          in {
            # kaine runs CachyOS, not NixOS: let home-manager configure
            # graphical apps but use nixGL to run them against the system
            # NVIDIA driver. Vulkan is enabled because mpv (gpu-api=vulkan) and
            # zed render through it.
            targets.genericLinux.enable = true;
            targets.genericLinux.nixGL = {
              # With --impure, nixGL reads the running driver version from
              # /proc/driver/nvidia/version and fetches the matching driver.
              #
              # home-manager finds the wrappers under `.auto` on its own.
              packages = import "${nixGLPatched}/default.nix" nixGLPackageArgs;
              defaultWrapper = "nvidia";
              vulkan.enable = true;
            };

            # Auto-detection is impure by construction (it reads /proc and uses
            # `builtins.currentTime` to defeat caching), so kaine's config only
            # ever evaluates with `--impure`. That flag can't be moved into
            # nix.conf or NIX_CONFIG — nix re-derives `pure-eval` from the
            # command line after loading the config, so a `pure-eval = false`
            # there is silently ignored. It has to be on the command line, so
            # ship a wrapper that always passes it. A script rather than a shell
            # alias because fish is the login shell here but only nushell is
            # home-manager-managed, so `home.shellAliases` wouldn't reach fish.
            home.packages = [
              (pkgs.writeShellScriptBin "nhs" ''
                exec ${pkgs.nh}/bin/nh home switch "$@" -- --impure
              '')
            ];
            home.shellAliases.nhl = lib.mkForce "nh home switch -- --impure --override-input neovim-config path:${config.home.homeDirectory}/git/neovim-config";
          })
        ];
      };

      "jonaa@surface" = mkHome {
        system = "x86_64-linux";
        username = "jonaa";
        modules = [./profiles/desktop.nix];
        userConfig =
          defaultUserConfig
          // {
            sshKeyFile = "~/.ssh/id_ed25519";
          };
        hostConfig = {
          lowEndGpu = true;
        };
      };

      # Minimal profile for any machine
      # builtins.getEnv returns "" in pure eval (CI), fall back so the config can still be checked
      "minimal" = let
        u = builtins.getEnv "USER";
      in
        mkHome {
          system = "x86_64-linux";
          username =
            if u != ""
            then u
            else "user";
          modules = [./profiles/minimal.nix];
        };
    };
  };
}
