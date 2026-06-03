{
  config,
  lib,
  ...
}: let
  settings = {
    fps_limit = 0;
    gpu_stats = true;
    gpu_temp = true;
    gpu_power = true;
    cpu_stats = true;
    cpu_temp = true;
    ram = true;
    vram = true;
    fps = true;
    frametime = true;
    frame_timing = true;
    font_size = 20;
    position = "top-left";
    toggle_hud = "Shift_R+F12";
  };

  # Same serialization as the home-manager mangohud module: a bare key for
  # `true`, `key=0` for `false`, `key=value` otherwise.
  renderSettings = attrs:
    lib.concatStringsSep "\n" (lib.mapAttrsToList
      (k: v:
        if lib.isBool v
        then
          (
            if v
            then k
            else "${k}=0"
          )
        else "${k}=${toString v}")
      attrs)
    + "\n";

  # On non-NixOS the overlay is an injected Vulkan/GL layer that must match the
  # system Vulkan loader, so the binary comes from the system package manager
  # and we only write the config. On NixOS, install + configure via the module.
  onGenericLinux = config.targets.genericLinux.enable;
in {
  programs.mangohud = lib.mkIf (!onGenericLinux) {
    enable = true;
    inherit settings;
  };

  xdg.configFile."MangoHud/MangoHud.conf" = lib.mkIf onGenericLinux {
    text = renderSettings settings;
  };

  home.sessionVariables.MANGOHUD = "1";
}
