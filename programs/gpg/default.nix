{ config, lib, pkgs, ... }: {
  # home.packages = with pkgs; [
  #   pinentry-curses
  # ];

  programs.gpg = {
    enable = true;
    settings = {
      default-key = "44F7B7979D3A27B189E0841E8333735E784DF9D4";
    };
  };

  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 36000;
    maxCacheTtl = 36000;
    defaultCacheTtlSsh = 36000;
    maxCacheTtlSsh = 36000;
    enableSshSupport = true;
    pinentryFlavor = "curses";
  };
}
