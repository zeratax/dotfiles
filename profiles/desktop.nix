{pkgs, ...}: {
  imports = [
    ./minimal.nix
    ../programs/firefox
    ../programs/ghostty
    ../programs/gpg
    ../programs/niri
    ../programs/mpv
    ../programs/vesktop
    ../programs/zed
  ];

  home = {
    packages = with pkgs; [
      keepassxc
      wl-clipboard
      signal-desktop
    ];
  };
}
