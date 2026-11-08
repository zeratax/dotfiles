{pkgs, ...}: {
  # Launcher, wallpaper, lock, idle, network and bluetooth are handled by
  # noctalia (../noctalia), the terminal is ghostty.
  home.packages = with pkgs; [
    # screenshot primitives
    grim
    slurp
    swappy

    # viewers
    imv
    zathura

    # audio mixer
    pavucontrol
  ];
}
