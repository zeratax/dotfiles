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
      inputs.nixpkgs.follows = "nixpkgs";
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
    # driver (see hosts/kaine.nix).
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
    self,
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
      gpgSshSupport = false;
      sshKeyFile = "~/.ssh/id_ed25519";
      githubUser = "ZerataX";
    };

    workUserConfig = {
      gitUserName = "Jona Abdinghoff";
      gitUserEmail = "jabdinghoff@lancier-monitoring.de";
      gpgSigningKey = null;
      gpgSignByDefault = false;
      gpgSshSupport = false;
      sshKeyFile = "~/.ssh/id_ed25519";
      githubUser = "jabdinghoff";
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
        # home-manager re-imports nixpkgs with the modules' nixpkgs.* options, so
        # config set here would be dropped; unfree is allowed in profiles/minimal.nix.
        pkgs = nixpkgs.legacyPackages.${system};
        extraSpecialArgs = {
          inherit nur nixos-vscode-server mpv-prescalers neovim-config jj-starship jj-hunk noctalia-shell nirinit llm-agents nixGL nixpkgs-nixgl userConfig hostConfig;
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

    # Built by CI (DeterminateCI builds every check), so unformatted code fails
    # the PR instead of piling up until the next `nix fmt`.
    checks = forAllSystems (system: {
      formatting = nixpkgs.legacyPackages.${system}.runCommand "check-formatting" {} ''
        ${nixpkgs.lib.getExe self.formatter.${system}} --check ${self}
        touch $out
      '';
    });

    homeConfigurations = {
      # WSL work machines
      "jabdinghoff@LT-JABDINGHOFF" = mkHome {
        system = "x86_64-linux";
        username = "jabdinghoff";
        modules = [./profiles/wsl.nix];
        userConfig = workUserConfig;
      };

      "jabdinghoff@sf-jabdinghoff" = mkHome {
        system = "aarch64-linux";
        username = "jabdinghoff";
        modules = [./profiles/wsl.nix];
        userConfig = workUserConfig;
      };

      "jonaa@kaine" = mkHome {
        system = "x86_64-linux";
        username = "jonaa";
        modules = [
          ./profiles/gaming.nix
          ./services/moonshine-mic
          ./hosts/kaine.nix
        ];
      };

      "jonaa@surface" = mkHome {
        system = "x86_64-linux";
        username = "jonaa";
        modules = [./profiles/desktop.nix ./programs/keepassxc/beta.nix];
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
