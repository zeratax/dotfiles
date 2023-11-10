{ config, lib, pkgs, ... }: {
  programs.gpg = {
    enable = true;
    settings = { default-key = "0x8333735E784DF9D4"; };
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    # pinentryFlavor = "curses";
    extraConfig = ''
      allow-loopback-pinentry
    '';
  };
}
