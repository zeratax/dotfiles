{
  config,
  lib,
  ...
}: let
  pluginSource = "https://github.com/noctalia-dev/noctalia-plugins";
  enablePlugin = {
    enabled = true;
    sourceUrl = pluginSource;
  };
in {
  programs.noctalia-shell = {
    enable = true;
    settings = {
      bar = {
        position = "top";
        backgroundOpacity = 0.95;
        widgets = {
          left = [
            {id = "Launcher";}
            {id = "plugin:kde-connect";}
            {id = "plugin:osk-toggle";}
            {id = "SystemMonitor";}
            {id = "plugin:port-monitor";}
            {id = "ActiveWindow";}
            {id = "MediaMini";}
            {id = "plugin:claude-code-panel";}
          ];
          center = [
            {id = "plugin:screen-toolkit";}
            {id = "Workspace";}
          ];
          right = [
            {id = "Tray";}
            {id = "NotificationHistory";}
            {id = "Bluetooth";}
            {id = "Network";}
            {id = "plugin:tailscale";}
            {id = "plugin:hassio";}
            {id = "Volume";}
            {id = "Brightness";}
            {id = "Battery";}
            {id = "plugin:privacy-indicator";}
            {id = "Clock";}
            {id = "ControlCenter";}
          ];
        };
      };
      colorSchemes = {
        useWallpaperColors = true;
      };
      appLauncher = {
        enableClipboardHistory = true;
        enableClipPreview = true;
      };
      wallpaper = {
        overviewEnabled = true;
      };
      location = {
        name = "Münster";
      };
      templates = {
        activeTemplates = [
          {
            id = "gtk";
            enabled = true;
          }
          {
            id = "qt";
            enabled = true;
          }
          {
            id = "niri";
            enabled = true;
          }
        ];
      };
      idle = {
        enabled = true;
        screenOffTimeout = 600;
        lockTimeout = 660;
        suspendTimeout = 1800;
        fadeDuration = 5;
        screenOffCommand = "";
        lockCommand = "";
        suspendCommand = "";
        resumeScreenOffCommand = "";
        resumeLockCommand = "";
        resumeSuspendCommand = "";
        customCommands = "[]";
      };
    };
    plugins = {
      sources = [
        {
          enabled = true;
          name = "Official Noctalia Plugins";
          url = pluginSource;
        }
      ];
      states = lib.genAttrs [
        "file-search"
        "hassio"
        "kagi-quick-search"
        "monitor-layout"
        "polkit-agent"
        "port-monitor"
        "privacy-indicator"
        "unicode-picker"
      ] (_: enablePlugin);
      version = 2;
    };
    pluginSettings = {
      privacy-indicator = {
        hideInactive = true;
        enableToast = true;
        removeMargins = false;
        iconSpacing = 4;
        activeColor = "primary";
        inactiveColor = "none";
        micFilterRegex = "";
        camFilterRegex = "wireplumber|pipewire";
      };
    };
  };
}
