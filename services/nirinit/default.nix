{nirinit, pkgs, ...}: {
  xdg.configFile."nirinit/config.toml".source =
    (pkgs.formats.toml {}).generate "nirinit-config.toml" {
      skip.apps = [
        "noctalia-shell"
        "xwayland-satellite"
      ];
    };

  systemd.user.services.nirinit = {
    Unit = {
      Description = "Nirinit session manager";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };
    Service = {
      Type = "simple";
      Restart = "always";
      ExecStart = "${nirinit.packages.${pkgs.stdenv.hostPlatform.system}.nirinit}/bin/nirinit --config %h/.config/nirinit/config.toml";
    };
    Install = {
      WantedBy = ["graphical-session.target"];
    };
  };
}
