{pkgs, lib, ...}: {
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
      signal-desktop
    ];

    file.".mozilla/native-messaging-hosts/pywalfox.json".text = builtins.toJSON {
      name = "pywalfox";
      description = "Pywalfox native messaging host";
      path = "${pkgs.pywalfox-native}/bin/pywalfox";
      type = "stdio";
      allowed_extensions = ["pywalfox@frewacom.org"];
    };
  };
}
