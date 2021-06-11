{ config, lib, pkgs, ... }:
let
  mpv-gpu-api = "vulkan";
in
{
  programs.mpv = {
    enable = true;

    defaultProfiles = [ "gpu-hq" ];

    config = {
      # General 
      gpu-api = mpv-gpu-api;

      spirv-compiler = "shaderc";

      hwdec = "auto-safe";
      vo = "gpu";

      # Cache
      # Uses a large seekable RAM cache even for local input.
      cache = true;
      # cache-secs=300
      # Uses extra large RAM cache (needs cache=yes to make it useful).
      demuxer-max-bytes = "800M";
      demuxer-max-back-bytes = "200M";

      # Tweaks
      cursor-autohide = 100;
      force-window = "immediate";
      keep-open = true;
      fs = true;
      fs-screen = 1;

      #Priority
      slang = "gem,ger,gmh,de,deu,en,eng";
      alang = "ja,jpn,de,deu,ger,en,eng";

      # Subs
      demuxer-mkv-subtitle-preroll = true;
      sub-ass-vsfilter-blur-compat = false;
      sub-fix-timing = false;
      # the following options only apply to subtitles without own styling (i.e. not ASS but e.g. SRT)
      sub-font = "Open Sans Semibold";
      sub-font-size = 48;
      sub-color = "#FFFFFFFF";
      sub-border-color = "#FF262626";
      sub-border-size = 3.2;
      sub-shadow-offset = 1;
      sub-shadow-color = "#33000000";
      sub-spacing = 0.5;

      # Volume
      volume = 100;
      volume-max = 200;

      # Screenshot
      screenshot-format = "png";
      screenshot-high-bit-depth = true;
      screenshot-png-compression = 1;
      screenshot-jpeg-quality = 95;
      screenshot-directory = "~/sync/mpv/Screenshots";
      screenshot-template = "%f-%wH.%wM.%wS.%wT-#%#00n";

      # Dither
      dither-depth = "auto";
      dither = "fruit";

      # Deband
      deband = false;
      deband-iterations = 4;
      deband-threshold = 50;
      deband-range = 16;
      deband-grain = 0;

      # Grain & Resizer
      glsl-shader = "~/.config/nixpkgs/mpv/shaders/${if (mpv-gpu-api  == "vulkan") then "vulkan/" else ""}ravu-r4.hook";
      fbo-format = if (mpv-gpu-api  == "vulkan") then "rgba16hf" else "rgba16f";
      no-scaler-resizes-only = true;

      # Resizer
      scale = "ewa_lanczossharp";
      dscale = "ewa_lanczos";
      cscale = "ewa_lanczossoft";

      # Interpolation
      blend-subtitles = true;
      video-sync = "display-resample";
      interpolation = true;
      tscale = "box";
      tscale-window = "sphinx";
      tscale-radius = 0.95;
      tscale-clamp = 0.0;
    };

    profiles = {
      WebDL-AoD = {
        profile-cond = ''string.match(p.filename, "%[1080p%+%]")~=nil'';
        deband = false;
      };

      WebDL = {
        profile-cond = ''string.match(p.filename, "%[Web%-DL%]")~=nil'';
        deband = true;
      };

      HorribleSubs = {
        profile-cond = ''string.match(p.filename, "HorribleSubs")~=nil'';
        deband = true;
      };

      EraiRaws = {
        profile-cond = ''string.match(p.filename, "Erai%-raws")~=nil'';
        deband = true;
      };

      SubsPlease = {
        profile-cond = ''string.match(p.filename, "SubsPlease")~=nil'';
        deband = true;
      };

      # Streaming
      # Naming Convensions:
      # V = Very Low, L = Low, M = Medium, H = High, U = Ultra, S = Supreme
      # Very Low = 480p, Low = 720p, Medium = 1080p, High = 1440p, Ultra = 2160p (4K), Supreme = 4320p (8K)
      # 30 = 30 frames per second, 60 = 60 frames per second
      # Use the switch e.g: --profile=H60
      
      S60 = {
        profile-desc = "4320p (8K) 60 FPS";
        ytdl-format = ''bestvideo[height<=?4320][fps<=?60][vcodec!=?vp9]+bestaudio/best'';
      };
      
      S30 = {
        profile-desc = "2160p (4K) 60 FPS";
        ytdl-format = ''bestvideo[height<=?4320][fps<=?30][vcodec!=?vp9]+bestaudio/best'';
      };
      
      U60 = {
        profile-desc = "2160p (4K) 60 FPS";
        ytdl-format = ''bestvideo[height<=?2160][fps<=?60][vcodec!=?vp9]+bestaudio/best'';
      };
      
      U30 = {
        profile-desc = "2160p (4K) 30 FPS";
        ytdl-format = ''bestvideo[height<=?2160][fps<=?30][vcodec!=?vp9]+bestaudio/best'';
      };
      
      H60 = {
        profile-desc = "1440p 60 FPS";
        ytdl-format = ''bestvideo[height<=?1440][fps<=?60][vcodec!=?vp9]+bestaudio/best'';
      };
      
      H30 = {
        profile-desc = "1440p 30 FPS";
        ytdl-format = ''bestvideo[height<=?1440][fps<=?30][vcodec!=?vp9]+bestaudio/best'';
      };
      
      M60 = {
        profile-desc = "1080p 60 FPS";
        ytdl-format = ''bestvideo[height<=?1080][fps<=?60][vcodec!=?vp9]+bestaudio/best'';
      };
      
      M30 = {
        profile-desc = "1080p 30 FPS";
        ytdl-format = ''bestvideo[height<=?1080][fps<=?30][vcodec!=?vp9]+bestaudio/best'';
      };
      
      L60 = {
        profile-desc = "720p 60 FPS";
        ytdl-format = ''bestvideo[height<=?720][fps<=?60][vcodec!=?vp9]+bestaudio/best'';
      };
      
      L30 = {
        profile-desc = "720p 30 FPS";
        ytdl-format = ''bestvideo[height<=?720][fps<=?30][vcodec!=?vp9]+bestaudio/best'';
      };
      
      V60 = {
        profile-desc = "480p 60 FPS";
        ytdl-format = ''bestvideo[height<=?480][fps<=?60][vcodec!=?vp9]+bestaudio/best'';
      };
      
      V30 = {
        profile-desc = "480p 30 FPS";
        ytdl-format = ''bestvideo[height<=?480][fps<=?30][vcodec!=?vp9]+bestaudio/best'';
      };

      # File Type Profiles
      # GIF Files
      "extension.gif" = {
        cache = false;
        no-pause = true;
        loop-file = true;
      };

      # WebM Files
      "extension.webm" = {
        no-pause = true;
        loop-file = true;
      };
    };
  };
}
