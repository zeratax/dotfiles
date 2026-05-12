{pkgs, ...}: {
  home.packages = [pkgs.volta];
  home.sessionPath = ["$HOME/.volta/bin"];
}
