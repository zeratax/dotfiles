{ pkgs, ... }:

{
  home.packages = with pkgs; [ argyllcms displaycal ];
}
