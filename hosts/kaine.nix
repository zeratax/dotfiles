# kaine: CachyOS desktop with an NVIDIA GPU, running home-manager standalone.
{
  config,
  lib,
  pkgs,
  nixGL,
  nixpkgs-nixgl,
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
    patches = [../patches/nixgl-pr221-open-module-version.patch];
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

  nvidiaVersion = pkgs.writeShellScript "nvidia-version" ''
    ${pkgs.gawk}/bin/awk 'NR == 1 { for (i = 1; i <= NF; i++) if ($i ~ /^[0-9]+\.[0-9.]+$/) { print $i; exit } }' /proc/driver/nvidia/version 2>/dev/null
  '';
  stamp = "${config.xdg.stateHome}/nhs/nvidia-version";

  nhs = pkgs.writeShellScriptBin "nhs" ''
    ver=$(${nvidiaVersion})
    ${pkgs.nh}/bin/nh home switch "$@" -- --impure || exit
    mkdir -p "$(dirname ${stamp})" && echo "$ver" > ${stamp}
  '';
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
  #
  # nhs also records which driver it built for, so the login check
  # below knows when a pacman nvidia update needs a rebuild. It keys
  # off the *loaded* module, not the package: a pacman hook would fire
  # before the reboot and rebuild for the old driver.
  home.packages = [nhs];

  systemd.user.services.nhs-nvidia = {
    Unit = {
      Description = "Rebuild home-manager when the loaded NVIDIA driver changed";
      # The switch runs from inside this unit; don't let the
      # activation restart it halfway through.
      X-SwitchMethod = "keep-old";
    };
    Service = {
      Type = "oneshot";
      Environment = [
        "PATH=${config.home.profileDirectory}/bin:/nix/var/nix/profiles/default/bin:/usr/bin"
        "NH_FLAKE=${config.home.homeDirectory}/Projects/dotfiles"
      ];
      ExecStart = toString (pkgs.writeShellScript "nhs-nvidia" ''
        cur=$(${nvidiaVersion})
        [ -n "$cur" ] || exit 0
        [ "$cur" = "$(cat ${stamp} 2>/dev/null)" ] && exit 0
        notify() { ${pkgs.libnotify}/bin/notify-send -a nhs "$@" || true; }
        notify "NVIDIA driver changed" "Rebuilding home-manager for $cur…"
        if ${lib.getExe nhs}; then
          notify "home-manager rebuilt" "nixGL now matches NVIDIA $cur"
        else
          notify -u critical "nhs failed" "journalctl --user -u nhs-nvidia"
          exit 1
        fi
      '');
    };
    Install.WantedBy = ["graphical-session.target"];
  };
  home.shellAliases.nhl = lib.mkForce "nh home switch -- --impure --override-input neovim-config path:${config.home.homeDirectory}/git/neovim-config";
}
