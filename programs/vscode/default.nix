{pkgs, ...}: {
  programs.vscode = {
    enable = true;

    profiles.default.extensions = with pkgs.vscode-extensions; [
      ### TOOLS
      ms-vscode-remote.remote-ssh
      github.copilot
      github.copilot-chat

      ### LANGUAGES
      scala-lang.scala
      jnoortheen.nix-ide
      vscodevim.vim
    ];
  };
}
