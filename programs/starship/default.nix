{
  lib,
  jj-starship,
  pkgs,
  ...
}:
let
  jj-starship-bin = "${jj-starship.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/jj-starship";
in {
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      command_timeout = 3000;

      format = lib.concatStrings [
        "$directory"
        "\${custom.jj}"
        "$git_branch"
        "$git_status"
        "$nodejs"
        "$python"
        "$rust"
        "$kotlin"
        "$gradle"
        "$crystal"
        "$zig"
        "$swift"
        "$nix_shell"
        "$package"
        "$line_break"
        "$character"
      ];

      right_format = lib.concatStrings [
        "$memory_usage"
        "$cmd_duration"
      ];

      nodejs = {
        detect_files = ["package.json"];
      };

      package = {
        display_private = true;
      };

      memory_usage = {
        disabled = false;
        threshold = -1;
        symbol = " ";
      };

      custom.jj = {
        when = "${jj-starship-bin} detect";
        shell = [jj-starship-bin];
        format = "[$symbol](blue bold) $output ";
        symbol = "";
      };
    };
  };
}
