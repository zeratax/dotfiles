{ pkgs, ... }:
let
  font = "DejaVuSansM Nerd Font Mono";
in 
{
  programs.alacritty.enable = true;
  programs.alacritty.settings = {
    normal = {
      family = font;
      style = "Regular";
    };
    bold = {
      family = font;
      style = "Bold";
    };
    italic = {
      family = font;
      style = "Oblique";
    };
    bold_italic = {
      family = font;
      style = "Bold Oblique";
    };
  };
  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [ nerdfonts ];
}
