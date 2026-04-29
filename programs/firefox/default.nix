{pkgs, config, lib, ...}: {
  programs.firefox = {
    enable = true;
    configPath = ".mozilla/firefox";
  };

  home = lib.mkIf config.programs.noctalia-shell.enable {
    packages = [pkgs.pywalfox-native];
    file.".mozilla/native-messaging-hosts/pywalfox.json".text = builtins.toJSON {
      name = "pywalfox";
      description = "Pywalfox native messaging host";
      path = "${pkgs.pywalfox-native}/bin/pywalfox";
      type = "stdio";
      allowed_extensions = ["pywalfox@frewacom.org"];
    };
  };

  programs.noctalia-shell.settings.templates.activeTemplates =
    lib.mkIf config.programs.noctalia-shell.enable [
      {id = "pywalfox"; enabled = true;}
    ];
}
