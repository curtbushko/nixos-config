let
  module = import ../ghostty.nix {
    config = {
      ns.terminals.enable = true;
      lib.stylix.colors = builtins.listToAttrs (map (name: {
          inherit name;
          value = "000000";
        }) [
          "base00"
          "base01"
          "base02"
          "base03"
          "base04"
          "base05"
          "base06"
          "base07"
          "base08"
          "base09"
          "base0A"
          "base0B"
          "base0C"
          "base0D"
          "base0E"
          "base0F"
        ]);
    };
    pkgs.stdenv.hostPlatform = {
      isLinux = false;
      isDarwin = false;
    };
    lib = {
      mkIf = _: value: value;
      optionalString = _: _: "";
    };
  };
  text = module.config.xdg.configFile."ghostty/config".text;
  contains = needle: builtins.replaceStrings [needle] [""] text != text;
in
  assert builtins.all contains [
    "keybind = super+t=new_tab"
    "keybind = super+w=close_tab"
    "keybind = super+h=previous_tab"
    "keybind = super+l=next_tab"
    "keybind = super+j=goto_split:down"
    "keybind = super+k=goto_split:up"
    "keybind = super+space=toggle_command_palette"
    "keybind = alt+super+minus=resize_split:left,10"
    "keybind = alt+super+equal=resize_split:right,10"
  ];
  assert !contains "keybind = super+k=clear_screen"; true
