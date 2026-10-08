{
  config,
  lib,
  pkgs,
  llm-agents,
  ...
}: let
  claude-desktop = llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-desktop;

  # claude-desktop runs in a buildFHSEnv sandbox that bind-mounts the host's /etc/fonts but
  # not /usr/share. On non-NixOS hosts every font dir and conf.d link in there points into
  # /usr/share, so the app and its browser pane render system-ui/monospace text as nothing.
  # Hand it a fontconfig that only references /nix/store and ~/.local/share/fonts instead.
  sandboxFontsConf = pkgs.writeText "claude-desktop-fonts.conf" ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
    ${lib.concatMapStrings (p: "  <dir>${p}/share/fonts</dir>\n") (with pkgs; [
      dejavu_fonts
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      liberation_ttf
    ])}
      <dir prefix="xdg">fonts</dir>
      <include>${pkgs.fontconfig.out}/etc/fonts/conf.d</include>
      <cachedir prefix="xdg">fontconfig</cachedir>
    </fontconfig>
  '';
in {
  imports = [
    ./minimal.nix
    ../programs/ghostty
    ../programs/mpv
    ../programs/zed
  ];
  home = {
    packages = with pkgs; [
      keepassxc
      obsidian
      (
        if config.targets.genericLinux.enable
        then
          symlinkJoin {
            name = "claude-desktop";
            paths = [claude-desktop];
            nativeBuildInputs = [makeWrapper];
            postBuild = ''
              wrapProgram $out/bin/claude-desktop \
                --set FONTCONFIG_FILE ${sandboxFontsConf}
            '';
          }
        else claude-desktop
      )
      llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode2-desktop
      # Electron only auto-detects kwallet when XDG_CURRENT_DESKTOP=KDE; under niri it falls back and errors.
      (symlinkJoin {
        name = "signal-desktop";
        paths = [signal-desktop];
        nativeBuildInputs = [makeWrapper];
        postBuild = ''
          wrapProgram $out/bin/signal-desktop \
            --add-flags "--password-store=kwallet6"
        '';
      })

      wl-clipboard

      # media
      spotify
      transmission_4-qt
      syncplay
    ];
  };
}
