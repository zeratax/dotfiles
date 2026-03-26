{pkgs, ...}: {
  programs.vscode = {
    enable = true;

    extensions = with pkgs.vscode-extensions; [
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
