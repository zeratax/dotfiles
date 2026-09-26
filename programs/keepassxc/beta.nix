# KeePassXC 2.8.0 beta, for Linux Quick Unlock via polkit (keepassxreboot/
# keepassxc#8983; not in any 2.7.x). On surface that lets face auth (visage in
# nixos-config's polkit-1 PAM stack, password as fallback) re-unlock a
# database after auto-lock; the master password is still needed once per
# session. Only surface imports this: other hosts stay on the stable package.
#
# nixpkgs' recipe is Qt5; 2.8 moved to Qt6 and additionally needs xkbcommon
# (Wayland auto-type) and keyutils. Drop this module once 2.8.0 stable is in
# nixpkgs.
{...}: {
  nixpkgs.overlays = [
    (final: prev: {
      keepassxc = prev.keepassxc.overrideAttrs (old: {
        version = "2.8.0-beta1";
        src = prev.fetchurl {
          url = "https://github.com/keepassxreboot/keepassxc/releases/download/2.8.0-beta1/keepassxc-2.8.0-beta1-src.tar.xz";
          hash = "sha256-v7rl6iUDLk4BEP7daBufl9iZOVQBVRinfBDwRhAJiRc=";
        };
        patches = []; # the nixpkgs patch is darwin-only

        nativeBuildInputs = with prev; [
          asciidoctor
          cmake
          pkg-config
          qt6.qttools
          qt6.wrapQtAppsHook
          wrapGAppsHook3
        ];
        buildInputs = with prev; [
          botan3
          curl
          keyutils
          libargon2
          libusb1
          libxi
          libxkbcommon
          libxtst
          minizip
          pcsclite
          qrencode
          qt6.qtbase
          qt6.qtsvg
          qt6.qtwayland
          readline
          zlib
        ];

        # nixpkgs' checkPhase hard-codes the Qt5 plugin path
        doCheck = false;
      });
    })
  ];
}
