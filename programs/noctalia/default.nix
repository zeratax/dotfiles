{config, ...}: {
  programs.noctalia = {
    enable = true;
    settings = {
      shell = {
        polkit_agent = true;
        # choices made in the wizard land in settings.toml and override this file
        setup_wizard_enabled = false;
        privacy.cam_filter_regex = "wireplumber|pipewire";
      };
      bar.main = {
        position = "top";
        background_opacity = 0.95;
        # full width, v5 insets the bar by default
        margin_ends = 0;
        capsule = true;
        start = [
          "launcher"
          "phone-connect"
          "osk-toggle"
          "cpu"
          "temp"
          "ram"
          "portctl"
          "active_window"
          "media"
        ];
        center = [
          "screen-toolkit"
          "workspaces"
        ];
        end = [
          "tray"
          "notifications"
          "bluetooth"
          "network"
          "tailscale"
          "hassio"
          "volume"
          "brightness"
          "battery"
          "privacy"
          "clock"
          "control-center"
        ];
      };
      widget = {
        privacy.hide_inactive = true;
        portctl.type = "rxtsel/portctl:indicator";
        hassio.type = "pozzoo/hassio:status";
      };
      theme = {
        source = "wallpaper";
        wallpaper_scheme = "m3-tonal-spot";
        templates.builtin_ids = [
          "gtk3"
          "gtk4"
          "qt"
          "niri"
        ];
      };
      wallpaper.directory = "${config.home.homeDirectory}/Pictures/Wallpapers";
      # blurred wallpaper in the niri overview, see the layer-rule in ../niri
      backdrop.enabled = true;
      location.address = "Münster";
      idle = {
        pre_action_fade_seconds = 5;
        behavior_order = [
          "screen-off"
          "lock"
          "suspend"
        ];
        behavior = {
          screen-off = {
            timeout = 600;
            action = "screen_off";
            enabled = true;
          };
          lock = {
            timeout = 660;
            action = "lock";
            enabled = true;
          };
          suspend = {
            timeout = 1800;
            action = "suspend";
            enabled = true;
          };
        };
      };
      plugins = {
        # third-party code, so don't let it change underneath us every 6 hours
        auto_update = "none";
        enabled = [
          "liamwh/emoji-picker"
          "nightwatch75/file-search"
          "pozzoo/hassio"
          "raycursive/niri-displays"
          "rxtsel/portctl"
        ];
      };
      plugin_settings."rxtsel/portctl".hide_system_ports = false;
    };
  };
}
