{pkgs, ...}: {
  imports = [
    ./minimal.nix
    ../programs/firefox
    ../programs/ghostty
    ../programs/gpg
    ../programs/niri
    ../programs/mpv
    ../programs/vesktop
    ../programs/zed
  ];

  home = {
    packages = with pkgs; [
      keepassxc
      wl-clipboard
      signal-desktop

      # noctalia plugin dependencies
      (wvkbd.overrideAttrs {
        makeFlags = ["LAYOUT=deskintl"];
        meta.mainProgram = "wvkbd-deskintl";
      })
      ffmpeg # screen-toolkit recording
      imagemagick # screen-toolkit
      satty # screenshot editor
      sqlite # zed-provider
      tesseract # screenshot OCR
      wf-recorder # screen recording
      zbar # screen-toolkit QR/barcode scanning
    ];
  };
}
