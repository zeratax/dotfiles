{pkgs, ...}: {
  imports = [
    ./minimal.nix
    ../programs/firefox
    ../programs/ghostty
    ../programs/gpg
    ../programs/kde-connect
    ../programs/mpv
    ../programs/niri
    ../programs/screen-toolkit
    ../programs/tailscale
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
