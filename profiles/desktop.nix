{pkgs, ...}: {
  imports = [
    ./minimal.nix
    ../programs/ghostty
    ../programs/gpg
    ../programs/niri
    ../programs/mpv
    ../programs/vesktop
    ../programs/zed
  ];

  home = {
    packages = with pkgs; [
      firefox
      keepassxc
      wl-clipboard
    ];
  };
}
