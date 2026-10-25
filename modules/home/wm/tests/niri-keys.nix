let
  names = [
    "toggle-overview"
    "focus-column-left"
    "focus-window-or-monitor-down"
    "focus-window-or-monitor-up"
    "focus-column-right"
    "move-column-left"
    "move-window-down"
    "move-window-up"
    "move-column-right"
    "fullscreen-window"
    "switch-preset-column-width"
    "switch-preset-window-height"
    "quit"
    "close-window"
    "show-hotkey-overlay"
  ];
  actions =
    builtins.listToAttrs (map (name: {
        inherit name;
        value = name;
      })
      names)
    // {
      set-window-width = width: width;
      spawn = command: command;
    };
  module = import ../niri.nix {
    config = {
      ns.wm.niri.enable = true;
      lib.niri = {inherit actions;};
    };
    inputs = {};
    pkgs = {};
    lib.mkIf = _: value: value;
  };
  binds = module.config.programs.niri.settings.binds;
in
  assert binds."Alt+T".action.spawn == "ghostty";
  assert binds."Alt+Return".action.spawn == "ghostty";
  assert binds."Alt+H".action == "focus-column-left";
  assert binds."Alt+J".action == "focus-window-or-monitor-down";
  assert binds."Alt+K".action == "focus-window-or-monitor-up";
  assert binds."Alt+L".action == "focus-column-right";
  assert binds."Alt+Ctrl+H".action == "move-column-left";
  assert binds."Alt+Ctrl+J".action == "move-window-down";
  assert binds."Alt+Ctrl+K".action == "move-window-up";
  assert binds."Alt+Ctrl+L".action == "move-column-right";
  assert binds."Alt+Ctrl+Minus".action == "-10%";
  assert binds."Alt+Ctrl+Equal".action == "+10%";
  assert binds."Alt+Ctrl+W".action == "switch-preset-column-width";
  assert binds."Alt+F".action == "fullscreen-window";
  assert binds."Mod+Tab".action == "toggle-overview";
  assert binds."Alt+Tab".action == "toggle-overview";
  assert binds."Alt+Q".action == "close-window";
  assert binds."Alt+M".action == "quit";
  assert binds."Ctrl+Alt+Delete".action == "quit";
  assert binds."Alt+Space".action.spawn == ["vicinae" "vicinae://toggle"];
  assert binds."Alt+V".action.spawn == ["vicinae" "vicinae://extensions/vicinae/clipboard/history"];
  assert builtins.all (key: builtins.substring 0 4 key != "Mod+" || key == "Mod+Tab") (builtins.attrNames binds);
  assert builtins.all (key: binds.${key}.action != "switch-preset-window-height") (builtins.filter (key: builtins.substring 0 4 key == "Alt+") (builtins.attrNames binds)); true
