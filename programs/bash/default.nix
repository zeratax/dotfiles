# Adjusted from Sensible Bash - An attempt at saner Bash defaults https://github.com/mrzool/bash-sensible
{...}: {
  programs.bash = {
    enable = true;
    sessionVariables = {
      # automatically trim long paths in the prompt (requires bash 4.x)
      PROMPT_DIRTRIM = 2;
      # record each line as it gets issued
      PROMPT_COMMAND = "history -a";
      # use standard iso 8601 timestamp
      # %F equivalent to %Y-%m-%d
      # %T equivalent to %H:%M:%S (24-hours format)
      HISTTIMEFORMAT = "%F %T ";
      # No CDPATH here: these variables are exported from ~/.profile, and an
      # exported CDPATH makes `cd` print the new directory, which breaks
      # `$(cd dir && pwd)` in every script started from the session.
    };
    shellOptions = [
      # update window size after every command
      "checkwinsize"
      # turn on recursive globbing (enables ** to recurse all directories)
      "globstar"
      # case-insensitive globbing (used in pathname expansion)
      "nocaseglob"
      # append to the history file, don't overwrite it
      "histappend"
      # save multi-line commands as one command
      "cmdhist"
      # prepend cd to directory names automatically
      "autocd"
      # correct spelling errors during tab-completion
      "dirspell"
      # correct spelling errors in arguments supplied to cd
      "cdspell"
      # this allows you to bookmark your favorite places across the file system
      # define a variable containing a path and you will be able to cd into it regardless of the directory you're in
      "cdable_vars"
    ];
    historyIgnore = ["&" "[ ]*" "exit" "ls" "bg" "fg" "history" "clear"];
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

      # prevent file overwrite on stdout redirection, use `>|` to force
      set -o noclobber
    '';
  };
  programs.readline = {
    enable = true;
    variables = {
      colored-stats = true;
      visible-stats = true;
      completion-ignore-case = true;
      completion-map-case = true;
      completion-prefix-display-length = 3;
      mark-symlinked-directories = true;
      show-all-if-ambiguous = true;
    };
    extraConfig = ''
      Space: magic-space
      "\e[A": history-search-backward
      "\e[B": history-search-forward
      "\e[C": forward-char
      "\e[D": backward-char
    '';
  };
}
