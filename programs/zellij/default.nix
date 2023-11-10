{ pkgs, ... }:

{
  programs.bash = {
    shellAliases = {
      zwd = "zellij attach $(echo $(pwd) | sed 's/\\//\\\\/g') -c";
    };
  };
  home.sessionVariables = { ZELLIJ_AUTO_ATTACH = "true"; };
  
  programs.zellij = {
    enable = true;
    enableBashIntegration =
      false; # https://github.com/zellij-org/zellij/issues/2100
    settings = {
      # keybinds = {
      #   locked = [{
      #     action = [{ SwitchToMode = "Normal"; }];
      #     key = [{ Ctrl = "b"; }];
      #   }];
      #   normal = [
      #     {
      #       action = [ { Write = [ 2 ]; } { SwitchToMode = "Locked"; } ];
      #       key = [{ Char = "b"; }];
      #     }
      #     {
      #       action = [{ SwitchToMode = "Locked"; }];
      #       key = [ { Ctrl = "b"; } { Char = " "; } { Char = "\n"; } ];
      #     }
      #     {
      #       action = [{ SwitchToMode = "Pane"; }];
      #       key = [{ Char = "p"; }];
      #     }
      #     {
      #       action = [{ SwitchToMode = "Resize"; }];
      #       key = [{ Char = "r"; }];
      #     }
      #     {
      #       action = [{ SwitchToMode = "Tab"; }];
      #       key = [{ Char = "t"; }];
      #     }
      #     {
      #       action = [{ SwitchToMode = "Scroll"; }];
      #       key = [{ Char = "s"; }];
      #     }
      #     {
      #       action = [{ SwitchToMode = "Session"; }];
      #       key = [{ Char = "o"; }];
      #     }
      #     {
      #       action = [ "Quit" ];
      #       key = [{ Ctrl = "q"; }];
      #     }
      #     {
      #       action = [ { NewPane = null; } { SwitchToMode = "Locked"; } ];
      #       key = [{ Alt = "n"; }];
      #     }
      #     {
      #       action = [ { NewTab = null; } { SwitchToMode = "Locked"; } ];
      #       key = [{ Char = "N"; }];
      #     }
      #     {
      #       action = [ { NewPane = null; } { SwitchToMode = "Locked"; } ];
      #       key = [{ Char = "n"; }];
      #     }
      #     {
      #       action =
      #         [ { MoveFocusOrTab = "Left"; } { SwitchToMode = "Locked"; } ];
      #       key = [{ Char = "h"; }];
      #     }
      #     {
      #       action =
      #         [ { MoveFocusOrTab = "Right"; } { SwitchToMode = "Locked"; } ];
      #       key = [{ Char = "l"; }];
      #     }
      #     {
      #       action = [ { MoveFocus = "Down"; } { SwitchToMode = "Locked"; } ];
      #       key = [{ Char = "j"; }];
      #     }
      #     {
      #       action = [ { MoveFocus = "Up"; } { SwitchToMode = "Locked"; } ];
      #       key = [{ Char = "k"; }];
      #     }
      #     {
      #       action = [{ MoveFocusOrTab = "Left"; }];
      #       key = [ { Char = "H"; } { Alt = "h"; } ];
      #     }
      #     {
      #       action = [{ MoveFocusOrTab = "Right"; }];
      #       key = [ { Char = "L"; } { Alt = "l"; } ];
      #     }
      #     {
      #       action = [{ MoveFocus = "Down"; }];
      #       key = [ { Char = "J"; } { Alt = "j"; } ];
      #     }
      #     {
      #       action = [{ MoveFocus = "Up"; }];
      #       key = [ { Char = "K"; } { Alt = "k"; } ];
      #     }
      #     {
      #       action = [ "FocusPreviousPane" ];
      #       key = [ { Char = "["; } { Alt = "["; } ];
      #     }
      #     {
      #       action = [ "FocusNextPane" ];
      #       key = [ { Char = "]"; } { Alt = "["; } ];
      #     }
      #     {
      #       action = [ { NewPane = "Down"; } { SwitchToMode = "Locked"; } ];
      #       key = [{ Char = "-"; }];
      #     }
      #     {
      #       action = [ { NewPane = "Right"; } { SwitchToMode = "Locked"; } ];
      #       key = [{ Char = "\\"; }];
      #     }
      #     {
      #       action = [{ GoToTab = 1; }];
      #       key = [{ Char = "1"; }];
      #     }
      #     {
      #       action = [{ GoToTab = 2; }];
      #       key = [{ Char = "2"; }];
      #     }
      #     {
      #       action = [{ GoToTab = 3; }];
      #       key = [{ Char = "3"; }];
      #     }
      #     {
      #       action = [{ GoToTab = 4; }];
      #       key = [{ Char = "4"; }];
      #     }
      #     {
      #       action = [{ GoToTab = 5; }];
      #       key = [{ Char = "5"; }];
      #     }
      #     {
      #       action = [{ GoToTab = 6; }];
      #       key = [{ Char = "6"; }];
      #     }
      #     {
      #       action = [{ GoToTab = 7; }];
      #       key = [{ Char = "7"; }];
      #     }
      #     {
      #       action = [{ GoToTab = 8; }];
      #       key = [{ Char = "8"; }];
      #     }
      #     {
      #       action = [{ GoToTab = 9; }];
      #       key = [{ Char = "9"; }];
      #     }
      #     {
      #       action = [{ Resize = "Increase"; }];
      #       key = [{ Char = "="; }];
      #     }
      #     {
      #       action = [{ Resize = "Increase"; }];
      #       key = [{ Char = "+"; }];
      #     }
      #     {
      #       action = [{ Resize = "Decrease"; }];
      #       key = [{ Char = "-"; }];
      #     }
      #     {
      #       action = [{ Resize = "Left"; }];
      #       key = [ "Left" ];
      #     }
      #     {
      #       action = [{ Resize = "Down"; }];
      #       key = [ "Down" ];
      #     }
      #     {
      #       action = [{ Resize = "Up"; }];
      #       key = [ "Up" ];
      #     }
      #     {
      #       action = [{ Resize = "Right"; }];
      #       key = [ "Right" ];
      #     }
      #     {
      #       action = [ "ToggleTab" ];
      #       key = [ { Char = "      "; } { Char = "t"; } ];
      #     }
      #     {
      #       action =
      #         [ { SwitchToMode = "RenamePane"; } { PaneNameInput = [ 0 ]; } ];
      #       key = [{ Char = "c"; }];
      #     }
      #     {
      #       action =
      #         [ { SwitchToMode = "RenameTab"; } { TabNameInput = [ 0 ]; } ];
      #       key = [{ Char = "C"; }];
      #     }
      #     {
      #       action = [ "EditScrollback" { SwitchToMode = "Locked"; } ];
      #       key = [{ Char = "e"; }];
      #     }
      #   ];
      #   pane = [
      #     {
      #       action = [{ SwitchToMode = "Locked"; }];
      #       key = [{ Ctrl = "b"; }];
      #     }
      #     {
      #       action = [{ SwitchToMode = "Normal"; }];
      #       key = [{ Ctrl = "p"; }];
      #     }
      #     {
      #       action = [{ SwitchToMode = "Tab"; }];
      #       key = [{ Ctrl = "t"; }];
      #     }
      #     {
      #       action = [{ SwitchToMode = "Locked"; }];
      #       key = [ { Ctrl = "r"; } { Char = "\n"; } { Char = " "; } ];
      #     }
      #     {
      #       action = [{ SwitchToMode = "Scroll"; }];
      #       key = [{ Ctrl = "s"; }];
      #     }
      #     {
      #       action = [ "Quit" ];
      #       key = [{ Ctrl = "q"; }];
      #     }
      #     {
      #       action = [{ MoveFocus = "Left"; }];
      #       key = [ { Alt = "h"; } "Left" ];
      #     }
      #     {
      #       action = [{ MoveFocus = "Right"; }];
      #       key = [ { Alt = "l"; } "Right" ];
      #     }
      #     {
      #       action = [{ MoveFocus = "Down"; }];
      #       key = [ { Alt = "j"; } "Down" ];
      #     }
      #     {
      #       action = [{ MoveFocus = "Up"; }];
      #       key = [ { Alt = "k"; } "Up" ];
      #     }
      #     {
      #       action = [ "SwitchFocus" ];
      #       key = [{ Char = "p"; }];
      #     }
      #     {
      #       action = [ { NewPane = null; } { SwitchToMode = "Locked"; } ];
      #       key = [ { Char = "n"; } { Alt = "n"; } ];
      #     }
      #     {
      #       action = [{ NewPane = null; }];
      #       key = [{ Char = "N"; }];
      #     }
      #     {
      #       action = [ { NewPane = "Down"; } { SwitchToMode = "Locked"; } ];
      #       key = [{ Char = "d"; }];
      #     }
      #     {
      #       action = [ { NewPane = "Right"; } { SwitchToMode = "Locked"; } ];
      #       key = [{ Char = "r"; }];
      #     }
      #     {
      #       action = [ "TogglePaneFrames" { SwitchToMode = "Locked"; } ];
      #       key = [{ Char = "z"; }];
      #     }
      #     {
      #       action = [ "TogglePaneFrames" ];
      #       key = [{ Char = "Z"; }];
      #     }
      #     {
      #       action = [{ NewPane = "Down"; }];
      #       key = [{ Char = "D"; }];
      #     }
      #     {
      #       action = [{ NewPane = "Right"; }];
      #       key = [{ Char = "R"; }];
      #     }
      #     {
      #       action = [ "CloseFocus" { SwitchToMode = "Locked"; } ];
      #       key = [{ Char = "x"; }];
      #     }
      #     {
      #       action = [ "CloseFocus" ];
      #       key = [{ Char = "X"; }];
      #     }
      #     {
      #       action = [ "ToggleFocusFullscreen" { SwitchToMode = "Locked"; } ];
      #       key = [{ Char = "f"; }];
      #     }
      #     {
      #       action = [ "ToggleFocusFullscreen" ];
      #       key = [{ Char = "F"; }];
      #     }
      #     {
      #       action = [ "FocusPreviousPane" ];
      #       key = [{ Alt = "["; }];
      #     }
      #     {
      #       action = [ "FocusNextPane" ];
      #       key = [{ Alt = "]"; }];
      #     }
      #     {
      #       action = [ "ToggleFocusFullscreen" { SwitchToMode = "Normal"; } ];
      #       key = [{ Char = "f"; }];
      #     }
      #     {
      #       action = [ "TogglePaneFrames" { SwitchToMode = "Normal"; } ];
      #       key = [{ Char = "z"; }];
      #     }
      #     {
      #       action = [ "ToggleFloatingPanes" { SwitchToMode = "Normal"; } ];
      #       key = [{ Char = "w"; }];
      #     }
      #     {
      #       action =
      #         [ "TogglePaneEmbedOrFloating" { SwitchToMode = "Normal"; } ];
      #       key = [{ Char = "e"; }];
      #     }
      #     {
      #       action =
      #         [ { SwitchToMode = "RenamePane"; } { PaneNameInput = [ 0 ]; } ];
      #       key = [{ Char = "c"; }];
      #     }
      #   ];
      #   renametab = [
      #     {
      #       action = [{ SwitchToMode = "Normal"; }];
      #       key = [{ Ctrl = "r"; }];
      #     }
      #     {
      #       action = [{ SwitchToMode = "Locked"; }];
      #       key = [ { Ctrl = "b"; } { Ctrl = "s"; } { Char = " "; } ];
      #     }
      #     {
      #       action = [{ SwitchToMode = "Tab"; }];
      #       key = [{ Char = "\n"; }];
      #     }
      #     {
      #       action = [ { TabNameInput = [ 27 ]; } { SwitchToMode = "Tab"; } ];
      #       key = [ "Esc" ];
      #     }
      #     {
      #       action = [{ NewPane = null; }];
      #       key = [{ Alt = "n"; }];
      #     }
      #     {
      #       action = [{ MoveFocus = "Left"; }];
      #       key = [{ Alt = "h"; }];
      #     }
      #     {
      #       action = [{ MoveFocus = "Right"; }];
      #       key = [{ Alt = "l"; }];
      #     }
      #     {
      #       action = [{ MoveFocus = "Down"; }];
      #       key = [{ Alt = "j"; }];
      #     }
      #     {
      #       action = [{ MoveFocus = "Up"; }];
      #       key = [{ Alt = "k"; }];
      #     }
      #     {
      #       action = [ "FocusPreviousPane" ];
      #       key = [{ Alt = "["; }];
      #     }
      #     {
      #       action = [ "FocusNextPane" ];
      #       key = [{ Alt = "]"; }];
      #     }
      #   ];
      #   resize = [
      #     {
      #       action = [{ SwitchToMode = "Locked"; }];
      #       key = [{ Ctrl = "b"; }];
      #     }
      #     {
      #       action = [{ SwitchToMode = "Pane"; }];
      #       key = [{ Ctrl = "p"; }];
      #     }
      #     {
      #       action = [{ SwitchToMode = "Tab"; }];
      #       key = [{ Ctrl = "t"; }];
      #     }
      #     {
      #       action = [{ SwitchToMode = "Locked"; }];
      #       key = [ { Ctrl = "r"; } { Char = "\n"; } { Char = " "; } ];
      #     }
      #     {
      #       action = [{ SwitchToMode = "Scroll"; }];
      #       key = [{ Ctrl = "s"; }];
      #     }
      #     {
      #       action = [ "Quit" ];
      #       key = [{ Ctrl = "q"; }];
      #     }
      #     {
      #       action = [{ Resize = "Left"; }];
      #       key = [ { Char = "h"; } "Left" ];
      #     }
      #     {
      #       action = [{ Resize = "Down"; }];
      #       key = [ { Char = "j"; } "Down" ];
      #     }
      #     {
      #       action = [{ Resize = "Up"; }];
      #       key = [ { Char = "k"; } "Up" ];
      #     }
      #     {
      #       action = [{ Resize = "Right"; }];
      #       key = [ { Char = "l"; } "Right" ];
      #     }
      #     {
      #       action = [{ NewPane = null; }];
      #       key = [{ Alt = "n"; }];
      #     }
      #     {
      #       action = [{ MoveFocus = "Left"; }];
      #       key = [ { Alt = "h"; } "Left" ];
      #     }
      #     {
      #       action = [{ MoveFocus = "Right"; }];
      #       key = [ { Alt = "l"; } "Right" ];
      #     }
      #     {
      #       action = [{ MoveFocus = "Down"; }];
      #       key = [ { Alt = "j"; } "Down" ];
      #     }
      #     {
      #       action = [{ MoveFocus = "Up"; }];
      #       key = [ { Alt = "k"; } "Up" ];
      #     }
      #     {
      #       action = [ "FocusPreviousPane" ];
      #       key = [{ Alt = "["; }];
      #     }
      #     {
      #       action = [ "FocusNextPane" ];
      #       key = [{ Alt = "]"; }];
      #     }
      #   ];
      #   scroll = [
      #     {
      #       action = [{ SwitchToMode = "Locked"; }];
      #       key = [
      #         { Ctrl = "r"; }
      #         { Ctrl = "s"; }
      #         { Char = " "; }
      #         { Char = "\n"; }
      #       ];
      #     }
      #     {
      #       action = [{ SwitchToMode = "Tab"; }];
      #       key = [{ Ctrl = "t"; }];
      #     }
      #     {
      #       action = [{ SwitchToMode = "Normal"; }];
      #       key = [{ Ctrl = "s"; }];
      #     }
      #     {
      #       action = [{ SwitchToMode = "Pane"; }];
      #       key = [{ Ctrl = "p"; }];
      #     }
      #     {
      #       action = [ "Quit" ];
      #       key = [{ Ctrl = "q"; }];
      #     }
      #     {
      #       action = [ "ScrollDown" ];
      #       key = [ { Char = "j"; } "Down" ];
      #     }
      #     {
      #       action = [ "ScrollUp" ];
      #       key = [ { Char = "k"; } "Up" ];
      #     }
      #     {
      #       action = [ "PageScrollDown" ];
      #       key = [ { Ctrl = "f"; } "PageDown" ];
      #     }
      #     {
      #       action = [ "PageScrollUp" ];
      #       key = [ { Ctrl = "b"; } "PageUp" ];
      #     }
      #     {
      #       action = [{ NewPane = null; }];
      #       key = [{ Alt = "n"; }];
      #     }
      #     {
      #       action = [{ MoveFocus = "Left"; }];
      #       key = [{ Alt = "h"; }];
      #     }
      #     {
      #       action = [{ MoveFocus = "Right"; }];
      #       key = [{ Alt = "l"; }];
      #     }
      #     {
      #       action = [{ MoveFocus = "Down"; }];
      #       key = [{ Alt = "j"; }];
      #     }
      #     {
      #       action = [{ MoveFocus = "Up"; }];
      #       key = [{ Alt = "k"; }];
      #     }
      #     {
      #       action = [ "FocusPreviousPane" ];
      #       key = [{ Alt = "["; }];
      #     }
      #     {
      #       action = [ "FocusNextPane" ];
      #       key = [{ Alt = "]"; }];
      #     }
      #     {
      #       action = [ "EditScrollback" { SwitchToMode = "Locked"; } ];
      #       key = [{ Char = "e"; }];
      #     }
      #   ];
      #   tab = [
      #     {
      #       action = [{ SwitchToMode = "Normal"; }];
      #       key = [{ Ctrl = "t"; }];
      #     }
      #     {
      #       action = [{ SwitchToMode = "Pane"; }];
      #       key = [{ Ctrl = "p"; }];
      #     }
      #     {
      #       action = [{ SwitchToMode = "Locked"; }];
      #       key = [ { Ctrl = "b"; } { Char = "\n"; } { Char = " "; } ];
      #     }
      #     {
      #       action = [{ SwitchToMode = "Scroll"; }];
      #       key = [{ Ctrl = "s"; }];
      #     }
      #     {
      #       action =
      #         [ { SwitchToMode = "RenameTab"; } { TabNameInput = [ 0 ]; } ];
      #       key = [{ Char = "r"; }];
      #     }
      #     {
      #       action = [ "Quit" ];
      #       key = [{ Ctrl = "q"; }];
      #     }
      #     {
      #       action = [ "FocusPreviousPane" ];
      #       key = [{ Alt = "["; }];
      #     }
      #     {
      #       action = [ "FocusNextPane" ];
      #       key = [{ Alt = "]"; }];
      #     }
      #     {
      #       action = [ "GoToPreviousTab" ];
      #       key = [{ Char = "h"; }];
      #     }
      #     {
      #       action = [ "GoToNextTab" ];
      #       key = [{ Char = "l"; }];
      #     }
      #     {
      #       action = [ "GoToNextTab" ];
      #       key = [{ Char = "j"; }];
      #     }
      #     {
      #       action = [ "GoToPreviousTab" ];
      #       key = [{ Char = "k"; }];
      #     }
      #     {
      #       action = [{ NewTab = null; }];
      #       key = [{ Char = "n"; }];
      #     }
      #     {
      #       action = [ "CloseTab" ];
      #       key = [{ Char = "x"; }];
      #     }
      #     {
      #       action = [{ MoveFocus = "Left"; }];
      #       key = [{ Alt = "h"; }];
      #     }
      #     {
      #       action = [{ MoveFocus = "Right"; }];
      #       key = [{ Alt = "l"; }];
      #     }
      #     {
      #       action = [{ MoveFocus = "Down"; }];
      #       key = [{ Alt = "j"; }];
      #     }
      #     {
      #       action = [{ MoveFocus = "Up"; }];
      #       key = [{ Alt = "k"; }];
      #     }
      #     {
      #       action = [{ GoToTab = 1; }];
      #       key = [{ Char = "1"; }];
      #     }
      #     {
      #       action = [{ GoToTab = 2; }];
      #       key = [{ Char = "2"; }];
      #     }
      #     {
      #       action = [{ GoToTab = 3; }];
      #       key = [{ Char = "3"; }];
      #     }
      #     {
      #       action = [{ GoToTab = 4; }];
      #       key = [{ Char = "4"; }];
      #     }
      #     {
      #       action = [{ GoToTab = 5; }];
      #       key = [{ Char = "5"; }];
      #     }
      #     {
      #       action = [{ GoToTab = 6; }];
      #       key = [{ Char = "6"; }];
      #     }
      #     {
      #       action = [{ GoToTab = 7; }];
      #       key = [{ Char = "7"; }];
      #     }
      #     {
      #       action = [{ GoToTab = 8; }];
      #       key = [{ Char = "8"; }];
      #     }
      #     {
      #       action = [{ GoToTab = 9; }];
      #       key = [{ Char = "9"; }];
      #     }
      #   ];
      #   unbind = true;
      # };
    };
  };
}
