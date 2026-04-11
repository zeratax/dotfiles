{...}: let
  # Helper to create a bind entry with ordered actions
  bind = keys: actions: {
    bind = {
      _args = if builtins.isList keys then keys else [keys];
      _children = actions;
    };
  };
  # Action with argument
  action = name: arg: {${name}._args = [arg];};
  # Action with no argument
  bare = name: {${name} = {};};
  # Action with children (for LaunchOrFocusPlugin etc.)
  actionWith = name: arg: children: {
    ${name} = {
      _args = [arg];
    } // children;
  };
  # Common combo: action then switch to locked
  locked = actions: actions ++ [(action "SwitchToMode" "locked")];
in {
  programs.bash = {
    shellAliases = {
      zwd = "zellij attach $(echo $(pwd) | sed 's/\\//\\\\/g') -c";
    };
  };
  home.sessionVariables = {ZELLIJ_AUTO_ATTACH = "true";};

  programs.zellij = {
    enable = true;
    enableBashIntegration =
      false; # https://github.com/zellij-org/zellij/issues/2100
    settings = {
      default_shell = "nu";
      default_mode = "locked";
      keybinds = {
        _props.clear-defaults = true;
        _children = [
          # locked
          {
            locked._children = [
              (bind "Ctrl g" [(action "SwitchToMode" "normal")])
            ];
          }
          # pane
          {
            pane._children = [
              (bind "left" [(action "MoveFocus" "left")])
              (bind "down" [(action "MoveFocus" "down")])
              (bind "up" [(action "MoveFocus" "up")])
              (bind "right" [(action "MoveFocus" "right")])
              (bind "c" [(action "SwitchToMode" "renamepane") (actionWith "PaneNameInput" 0 {})])
              (bind "d" (locked [(action "NewPane" "down")]))
              (bind "e" (locked [(bare "TogglePaneEmbedOrFloating")]))
              (bind "f" (locked [(bare "ToggleFocusFullscreen")]))
              (bind "h" [(action "MoveFocus" "left")])
              (bind "i" (locked [(bare "TogglePanePinned")]))
              (bind "j" [(action "MoveFocus" "down")])
              (bind "k" [(action "MoveFocus" "up")])
              (bind "l" [(action "MoveFocus" "right")])
              (bind "n" (locked [(bare "NewPane")]))
              (bind "p" [(action "SwitchToMode" "normal")])
              (bind "r" (locked [(action "NewPane" "right")]))
              (bind "s" (locked [(action "NewPane" "stacked")]))
              (bind "w" (locked [(bare "ToggleFloatingPanes")]))
              (bind "x" (locked [(bare "CloseFocus")]))
              (bind "z" (locked [(bare "TogglePaneFrames")]))
              (bind "tab" [(bare "SwitchFocus")])
            ];
          }
          # tab
          {
            tab._children = [
              (bind "left" [(bare "GoToPreviousTab")])
              (bind "down" [(bare "GoToNextTab")])
              (bind "up" [(bare "GoToPreviousTab")])
              (bind "right" [(bare "GoToNextTab")])
              (bind "1" (locked [(actionWith "GoToTab" 1 {})]))
              (bind "2" (locked [(actionWith "GoToTab" 2 {})]))
              (bind "3" (locked [(actionWith "GoToTab" 3 {})]))
              (bind "4" (locked [(actionWith "GoToTab" 4 {})]))
              (bind "5" (locked [(actionWith "GoToTab" 5 {})]))
              (bind "6" (locked [(actionWith "GoToTab" 6 {})]))
              (bind "7" (locked [(actionWith "GoToTab" 7 {})]))
              (bind "8" (locked [(actionWith "GoToTab" 8 {})]))
              (bind "9" (locked [(actionWith "GoToTab" 9 {})]))
              (bind "[" (locked [(bare "BreakPaneLeft")]))
              (bind "]" (locked [(bare "BreakPaneRight")]))
              (bind "b" (locked [(bare "BreakPane")]))
              (bind "h" [(bare "GoToPreviousTab")])
              (bind "j" [(bare "GoToNextTab")])
              (bind "k" [(bare "GoToPreviousTab")])
              (bind "l" [(bare "GoToNextTab")])
              (bind "n" (locked [(bare "NewTab")]))
              (bind "r" [(action "SwitchToMode" "renametab") (actionWith "TabNameInput" 0 {})])
              (bind "s" (locked [(bare "ToggleActiveSyncTab")]))
              (bind "t" [(action "SwitchToMode" "normal")])
              (bind "x" (locked [(bare "CloseTab")]))
              (bind "tab" [(bare "ToggleTab")])
            ];
          }
          # resize
          {
            resize._children = [
              (bind "left" [(action "Resize" "Increase left")])
              (bind "down" [(action "Resize" "Increase down")])
              (bind "up" [(action "Resize" "Increase up")])
              (bind "right" [(action "Resize" "Increase right")])
              (bind "+" [(action "Resize" "Increase")])
              (bind "-" [(action "Resize" "Decrease")])
              (bind "=" [(action "Resize" "Increase")])
              (bind "H" [(action "Resize" "Decrease left")])
              (bind "J" [(action "Resize" "Decrease down")])
              (bind "K" [(action "Resize" "Decrease up")])
              (bind "L" [(action "Resize" "Decrease right")])
              (bind "h" [(action "Resize" "Increase left")])
              (bind "j" [(action "Resize" "Increase down")])
              (bind "k" [(action "Resize" "Increase up")])
              (bind "l" [(action "Resize" "Increase right")])
              (bind "r" [(action "SwitchToMode" "normal")])
            ];
          }
          # move
          {
            move._children = [
              (bind "left" [(action "MovePane" "left")])
              (bind "down" [(action "MovePane" "down")])
              (bind "up" [(action "MovePane" "up")])
              (bind "right" [(action "MovePane" "right")])
              (bind "h" [(action "MovePane" "left")])
              (bind "j" [(action "MovePane" "down")])
              (bind "k" [(action "MovePane" "up")])
              (bind "l" [(action "MovePane" "right")])
              (bind "m" [(action "SwitchToMode" "normal")])
              (bind "n" [(bare "MovePane")])
              (bind "p" [(bare "MovePaneBackwards")])
              (bind "tab" [(bare "MovePane")])
            ];
          }
          # scroll
          {
            scroll._children = [
              (bind "Alt left" [(action "MoveFocusOrTab" "left") (action "SwitchToMode" "locked")])
              (bind "Alt down" [(action "MoveFocus" "down") (action "SwitchToMode" "locked")])
              (bind "Alt up" [(action "MoveFocus" "up") (action "SwitchToMode" "locked")])
              (bind "Alt right" [(action "MoveFocusOrTab" "right") (action "SwitchToMode" "locked")])
              (bind "e" (locked [(bare "EditScrollback")]))
              (bind "f" [(action "SwitchToMode" "entersearch") (actionWith "SearchInput" 0 {})])
              (bind "Alt h" [(action "MoveFocusOrTab" "left") (action "SwitchToMode" "locked")])
              (bind "Alt j" [(action "MoveFocus" "down") (action "SwitchToMode" "locked")])
              (bind "Alt k" [(action "MoveFocus" "up") (action "SwitchToMode" "locked")])
              (bind "Alt l" [(action "MoveFocusOrTab" "right") (action "SwitchToMode" "locked")])
              (bind "s" [(action "SwitchToMode" "normal")])
            ];
          }
          # search
          {
            search._children = [
              (bind "c" [(action "SearchToggleOption" "CaseSensitivity")])
              (bind "n" [(action "Search" "down")])
              (bind "o" [(action "SearchToggleOption" "WholeWord")])
              (bind "p" [(action "Search" "up")])
              (bind "w" [(action "SearchToggleOption" "Wrap")])
            ];
          }
          # session
          {
            session._children = [
              (bind "a" [
                (actionWith "LaunchOrFocusPlugin" "zellij:about" {
                  floating = true;
                  move_to_focused_tab = true;
                })
                (action "SwitchToMode" "locked")
              ])
              (bind "c" [
                (actionWith "LaunchOrFocusPlugin" "configuration" {
                  floating = true;
                  move_to_focused_tab = true;
                })
                (action "SwitchToMode" "locked")
              ])
              (bind "d" [(bare "Detach")])
              (bind "l" [
                (actionWith "LaunchOrFocusPlugin" "zellij:layout-manager" {
                  floating = true;
                  move_to_focused_tab = true;
                })
                (action "SwitchToMode" "locked")
              ])
              (bind "o" [(action "SwitchToMode" "normal")])
              (bind "p" [
                (actionWith "LaunchOrFocusPlugin" "plugin-manager" {
                  floating = true;
                  move_to_focused_tab = true;
                })
                (action "SwitchToMode" "locked")
              ])
              (bind "s" [
                (actionWith "LaunchOrFocusPlugin" "zellij:share" {
                  floating = true;
                  move_to_focused_tab = true;
                })
                (action "SwitchToMode" "locked")
              ])
              (bind "w" [
                (actionWith "LaunchOrFocusPlugin" "session-manager" {
                  floating = true;
                  move_to_focused_tab = true;
                })
                (action "SwitchToMode" "locked")
              ])
            ];
          }
          # shared_among "normal" "locked"
          {
            shared_among = {
              _args = ["normal" "locked"];
              _children = [
                (bind "Alt left" [(action "MoveFocusOrTab" "left")])
                (bind "Alt down" [(action "MoveFocus" "down")])
                (bind "Alt up" [(action "MoveFocus" "up")])
                (bind "Alt right" [(action "MoveFocusOrTab" "right")])
                (bind "Alt +" [(action "Resize" "Increase")])
                (bind "Alt -" [(action "Resize" "Decrease")])
                (bind "Alt =" [(action "Resize" "Increase")])
                (bind "Alt [" [(bare "PreviousSwapLayout")])
                (bind "Alt ]" [(bare "NextSwapLayout")])
                (bind "Alt f" [(bare "ToggleFloatingPanes")])
                (bind "Alt h" [(action "MoveFocusOrTab" "left")])
                (bind "Alt i" [(action "MoveTab" "left")])
                (bind "Alt j" [(action "MoveFocus" "down")])
                (bind "Alt k" [(action "MoveFocus" "up")])
                (bind "Alt l" [(action "MoveFocusOrTab" "right")])
                (bind "Alt n" [(bare "NewPane")])
                (bind "Alt o" [(action "MoveTab" "right")])
                (bind "Alt p" [(bare "TogglePaneInGroup")])
                (bind "Alt Shift p" [(bare "ToggleGroupMarking")])
              ];
            };
          }
          # shared_except "locked" "renametab" "renamepane"
          {
            shared_except = {
              _args = ["locked" "renametab" "renamepane"];
              _children = [
                (bind "Ctrl g" [(action "SwitchToMode" "locked")])
                (bind "Ctrl q" [(bare "Quit")])
              ];
            };
          }
          # shared_except "locked" "entersearch"
          {
            shared_except = {
              _args = ["locked" "entersearch"];
              _children = [
                (bind "enter" [(action "SwitchToMode" "locked")])
              ];
            };
          }
          # shared_except "locked" "entersearch" "renametab" "renamepane"
          {
            shared_except = {
              _args = ["locked" "entersearch" "renametab" "renamepane"];
              _children = [
                (bind "esc" [(action "SwitchToMode" "locked")])
              ];
            };
          }
          # shared_except "locked" "entersearch" "renametab" "renamepane" "move"
          {
            shared_except = {
              _args = ["locked" "entersearch" "renametab" "renamepane" "move"];
              _children = [
                (bind "m" [(action "SwitchToMode" "move")])
              ];
            };
          }
          # shared_except "locked" "entersearch" "search" "renametab" "renamepane" "session"
          {
            shared_except = {
              _args = ["locked" "entersearch" "search" "renametab" "renamepane" "session"];
              _children = [
                (bind "o" [(action "SwitchToMode" "session")])
              ];
            };
          }
          # shared_except "locked" "tab" "entersearch" "renametab" "renamepane"
          {
            shared_except = {
              _args = ["locked" "tab" "entersearch" "renametab" "renamepane"];
              _children = [
                (bind "t" [(action "SwitchToMode" "tab")])
              ];
            };
          }
          # shared_among "normal" "resize" "tab" "scroll" "prompt" "tmux"
          {
            shared_among = {
              _args = ["normal" "resize" "tab" "scroll" "prompt" "tmux"];
              _children = [
                (bind "p" [(action "SwitchToMode" "pane")])
              ];
            };
          }
          # shared_among "normal" "resize" "search" "move" "prompt" "tmux"
          {
            shared_among = {
              _args = ["normal" "resize" "search" "move" "prompt" "tmux"];
              _children = [
                (bind "s" [(action "SwitchToMode" "scroll")])
              ];
            };
          }
          # shared_except "locked" "resize" "pane" "tab" "entersearch" "renametab" "renamepane"
          {
            shared_except = {
              _args = ["locked" "resize" "pane" "tab" "entersearch" "renametab" "renamepane"];
              _children = [
                (bind "r" [(action "SwitchToMode" "resize")])
              ];
            };
          }
          # shared_among "scroll" "search"
          {
            shared_among = {
              _args = ["scroll" "search"];
              _children = [
                (bind "PageDown" [(bare "PageScrollDown")])
                (bind "PageUp" [(bare "PageScrollUp")])
                (bind "left" [(bare "PageScrollUp")])
                (bind "down" [(bare "ScrollDown")])
                (bind "up" [(bare "ScrollUp")])
                (bind "right" [(bare "PageScrollDown")])
                (bind "Ctrl b" [(bare "PageScrollUp")])
                (bind "Ctrl c" [(bare "ScrollToBottom") (action "SwitchToMode" "locked")])
                (bind "d" [(bare "HalfPageScrollDown")])
                (bind "Ctrl f" [(bare "PageScrollDown")])
                (bind "h" [(bare "PageScrollUp")])
                (bind "j" [(bare "ScrollDown")])
                (bind "k" [(bare "ScrollUp")])
                (bind "l" [(bare "PageScrollDown")])
                (bind "u" [(bare "HalfPageScrollUp")])
              ];
            };
          }
          # entersearch
          {
            entersearch._children = [
              (bind "Ctrl c" [(action "SwitchToMode" "scroll")])
              (bind "esc" [(action "SwitchToMode" "scroll")])
              (bind "enter" [(action "SwitchToMode" "search")])
            ];
          }
          # renametab
          {
            renametab._children = [
              (bind "esc" [(bare "UndoRenameTab") (action "SwitchToMode" "tab")])
            ];
          }
          # shared_among "renametab" "renamepane"
          {
            shared_among = {
              _args = ["renametab" "renamepane"];
              _children = [
                (bind "Ctrl c" [(action "SwitchToMode" "locked")])
              ];
            };
          }
          # renamepane
          {
            renamepane._children = [
              (bind "esc" [(bare "UndoRenamePane") (action "SwitchToMode" "pane")])
            ];
          }
        ];
      };
    };
  };
}
