{ config, pkgs, ... }: {
  programs.oh-my-posh = {
    enable = true;
    settings = builtins.fromJSON (builtins.unsafeDiscardStringContext (
      # builtins.readFile "${pkgs.oh-my-posh}/share/oh-my-posh/themes/space.omp.json"
      builtins.readFile ./theme.json));
  };
}
