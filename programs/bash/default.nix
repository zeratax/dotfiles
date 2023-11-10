# Adjusted from Sensible Bash - An attempt at saner Bash defaults https://github.com/mrzool/bash-sensible
{ pkgs, ... }:

{
  programs.bash = {
    enable = true;
    sessionVariables = {
      # automatically trim long paths in the prompt (requires bash 4.x)
      PROMPT_DIRTRIM = 2;
      # record each line as it gets issued
      PROMPT_COMMAND = "history -a";
      # use standard iso 8601 timestamp
      # %f equivalent to %y-%m-%d
      # %t equivalent to %h:%m:%s (24-hours format)
      HISTTIMEFORMAT = "%f %t ";
      # this defines where cd looks for targets
      # add the directories you want to have fast access to, separated by colon
      # ex: cdpath=".:~:~/projects" will look for targets in the current working directory, in home and in the ~/projects folder
      CDPATH = ".";
    };
    shellOptions = [
      # update window size after every command
      "checkwinsize"
      # turn on recursive globbing (enables ** to recurse all directories)
      "globstar 2> /dev/null"
      # case-insensitive globbing (used in pathname expansion)
      "nocaseglob;"
      # append to the history file, don't overwrite it
      "histappend"
      # save multi-line commands as one command
      "cmdhist"
      # prepend cd to directory names automatically
      "autocd 2> /dev/null"
      # correct spelling errors during tab-completion
      "dirspell 2> /dev/null"
      # correct spelling errors in arguments supplied to cd
      "cdspell 2> /dev/null"
      # this allows you to bookmark your favorite places across the file system
      # define a variable containing a path and you will be able to cd into it regardless of the directory you're in
      "cdable_vars"
    ];
    historyIgnore = [ "&" "[ ]*" "exit" "ls" "bg" "fg" "history" "clear" ];
    historySize = 50000;
    historyFileSize = 100000;
    historyControl = [
      # avoid duplicate entries
      "erasedups"
      "ignoredups"
      "ignorespace"
    ];
    bashrcExtra = ''
      source ~/.nix-profile/etc/profile.d/hm-session-vars.sh
      source ${./config.bash}
    '';
  };
  programs.readline = {
    enable = true;
    variables = {
      colored-stats = true;
      visible-stats = true;
      completion-ignore-case = true;
      completion-prefix-display-length = 3;
      # show-all-if-ambiguous = true;
      # show-all-if-unmodified = true;
    };
  };
}
