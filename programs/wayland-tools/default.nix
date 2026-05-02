{pkgs, ...}: {
  home.packages = with pkgs; [
    # launchers
    fuzzel
    wofi

    # screenshot primitives
    grim
    slurp
    swappy

    # terminals
    foot
    kitty

    # viewers
    imv
    zathura

    # wallpaper & lock & idle
    swaybg
    swaylock-effects
    swayidle

    # system tray applets
    networkmanagerapplet
    blueman
    pavucontrol
  ];
}
