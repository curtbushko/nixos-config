{
  programs.alacritty = {
    settings = {
      env.TERM = "xterm-256color";
      key_bindings = [
        {
          key = "K";
          mods = "Command";
          chars = "ClearHistory";
        }
        {
          key = "V";
          mods = "Command";
          action = "Paste";
        }
        {
          key = "C";
          mods = "Command";
          action = "Copy";
        }
        {
          key = "Key0";
          mods = "Command";
          action = "ResetFontSize";
        }
        {
          key = "Equals";
          mods = "Command";
          action = "IncreaseFontSize";
        }
        {
          key = "Subtract";
          mods = "Command";
          action = "DecreaseFontSize";
        }
      ];
    };
  };
}
