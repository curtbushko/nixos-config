let
  render = import ../render-skhd.nix;
  bindings = import ../bindings.nix;
  expected = {
    "alt - t" = "open -a 'Rex Beta'";
    "alt - v" = ''omniwmctl command open-command-palette && sleep 0.2 && skhd -k "cmd - 3"'';
    "alt - return" = "open -a 'Rex Beta'";
    "alt - h" = "omniwmctl command focus left";
    "alt - j" = "omniwmctl command focus down";
    "alt - k" = "omniwmctl command focus up";
    "alt - l" = "omniwmctl command focus right";
    "alt + ctrl - h" = "omniwmctl command move-column left";
    "alt + ctrl - j" = "omniwmctl command move-window-down";
    "alt + ctrl - k" = "omniwmctl command move-window-up";
    "alt + ctrl - l" = "omniwmctl command move-column right";
    "alt + ctrl - 0x1B" = "omniwmctl command set-window-primary-span -10%";
    "alt + ctrl - 0x18" = "omniwmctl command set-window-primary-span +10%";
    "alt + ctrl - w" = "omniwmctl command cycle-size forward";
    "alt - f" = "omniwmctl command toggle-container-full-primary-span";
    "alt - tab" = "omniwmctl command toggle-overview";
    "cmd - tab" = "omniwmctl command toggle-overview";
    "alt - m" = "osascript -e 'tell application \"OmniWM\" to quit'";
  };
in
  assert builtins.all (key: bindings.${key} == expected.${key}) (builtins.attrNames expected);
  assert bindings ? "alt - m" && bindings ? "ctrl + alt - 0x75";
  assert bindings ? "alt - space" && bindings ? "alt - v";
  assert builtins.all (key: key == "cmd - tab" || builtins.substring 0 3 key != "cmd") (builtins.attrNames bindings);
  assert builtins.all (key: bindings.${key} != "omniwmctl command cycle-window-secondary-span forward") (builtins.attrNames bindings);
  assert render {"cmd - tab" = bindings."cmd - tab";}
  == "cmd - tab : omniwmctl command toggle-overview"; true
