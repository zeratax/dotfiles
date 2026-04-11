{
  lib,
  pkgs,
  userConfig,
  ...
}: {
  programs.gpg = {
    enable = true;
    settings = lib.mkIf (userConfig.gpgSigningKey != null) {
      default-key = userConfig.gpgSigningKey;
    };
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = userConfig.gpgSignByDefault;
    pinentry.package = pkgs.pinentry-curses;
    extraConfig = ''
      allow-loopback-pinentry
    '';
  };
}
