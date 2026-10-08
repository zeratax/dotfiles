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

  # nixGL's driver libs live in /nix/store, which the sandbox can see, so the app and WebGL
  # get the real GPU instead of software rendering.
  #
  # WebGPU still runs on SwiftShader: a hardware adapter only appears with X11 instead of
  # Wayland, --enable-features=Vulkan and --disable-gpu-sandbox (the GPU sandbox blocks the
  # loader from reading nixGL's ICD json), which isn't worth it for a pane that browses
  # arbitrary sites. --enable-unsafe-webgpu at least hands pages the SwiftShader adapter
  # instead of none.
  wrapped = config.lib.nixGL.wrap (pkgs.symlinkJoin {
    name = "claude-desktop";
    paths = [claude-desktop];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/claude-desktop \
        --set FONTCONFIG_FILE ${sandboxFontsConf} \
        --add-flags "--enable-unsafe-webgpu"
    '';
  });
in {
  home.packages = [
    (
      if config.targets.genericLinux.enable
      then wrapped
      else claude-desktop
    )
  ];
}
