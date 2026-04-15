{ ... }:
{
  programs.mangohud = {
    enable = true;
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
  };

  home.sessionVariables = {
    MANGOHUD = "1";
  };
}
