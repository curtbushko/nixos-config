let
  settings = import ../settings.nix;
  bindings = import ../bindings.nix;
  expected = {
    "cmd - return" = "open -na Ghostty";
    "cmd - t" = "open -na Ghostty";
    "cmd - space" = ''omniwmctl command open-command-palette && sleep 0.2 && skhd -k "cmd - 5"'';
    "cmd + shift - v" = "omniwmctl command open-command-palette";
    "cmd - tab" = "omniwmctl command toggle-overview";
    "cmd - q" = {
      firefox = null; # Pass Cmd+Q through to Firefox's native Quit action.
      "*" = "omniwmctl command close-focused-window";
    };
    "cmd - m" = "osascript -e 'tell application \"OmniWM\" to quit'";
    "ctrl + alt - 0x75" = "osascript -e 'tell application \"OmniWM\" to quit'";
    "cmd + shift - 0x2C" = ''open -a TextEdit "$HOME/.config/omniwm/KEYBINDINGS.md"'';
    "cmd - left" = "omniwmctl command focus left";
    "cmd - h" = "omniwmctl command focus left";
    "cmd - down" = "omniwmctl command focus down";
    "cmd - j" = "omniwmctl command focus down";
    "cmd - up" = "omniwmctl command focus up";
    "cmd - k" = "omniwmctl command focus up";
    "cmd - right" = "omniwmctl command focus right";
    "cmd - l" = "omniwmctl command focus right";
    "cmd + ctrl - left" = "omniwmctl command move-column left";
    "cmd + ctrl - h" = "omniwmctl command move-column left";
    "cmd + ctrl - right" = "omniwmctl command move-column right";
    "cmd + ctrl - l" = "omniwmctl command move-column right";
    "cmd + ctrl - down" = "omniwmctl command move-window-down";
    "cmd + ctrl - up" = "omniwmctl command move-window-up";
    "cmd + shift - 0x1B" = "omniwmctl command set-window-primary-span -10%";
    "cmd + shift - 0x18" = "omniwmctl command set-window-primary-span +10%";
    "cmd + alt - f" = "omniwmctl command toggle-container-full-primary-span";
    "cmd + alt - right" = "omniwmctl command cycle-size forward";
    "cmd + alt - left" = "omniwmctl command cycle-size forward";
    "cmd + alt - h" = "omniwmctl command cycle-size forward";
    "cmd + alt - l" = "omniwmctl command cycle-size forward";
    "cmd + alt - up" = "omniwmctl command cycle-window-secondary-span forward";
    "cmd + alt - down" = "omniwmctl command cycle-window-secondary-span forward";
  };
in
  assert bindings == expected;
  assert (import ../render-skhd.nix {
    "cmd - q" = expected."cmd - q";
    "cmd - tab" = expected."cmd - tab";
  })
  == ''
    cmd - q [
      * : omniwmctl command close-focused-window
      "firefox" ~
    ]
    cmd - tab : omniwmctl command toggle-overview'';
  assert builtins.length settings.workspaces == 1;
  assert map (workspace: workspace.name) settings.workspaces == ["1"];
  assert !settings.workspaceBar.enabled;
  assert settings.workspaceBar.position == "overlappingMenuBar";
  assert settings.workspaceBar.notchMode == "fillLeftOfNotch";
  assert !settings.workspaceBar.reserveLayoutSpace;
  assert settings.general.defaultLayoutType == "niri";
  assert settings.general.ipcEnabled;
  assert !settings.general.hotkeysEnabled;
  assert settings.niri.defaultContainerPrimarySpan == 0.33333;
  assert settings.niri.containerPrimarySpanPresets == [0.33333 0.5 0.66667];
  assert settings.niri.resizeStepPercent == 10;
  assert settings.gaps.size == 6;
  assert settings.gaps.fullscreenUsesOuterGaps;
  assert settings.gaps.outer
  == {
    left = 6;
    right = 6;
    top = 6;
    bottom = 6;
  };
  assert settings.focus.followsMouse && settings.focus.moveMouseToFocusedWindow;
  assert settings.focus.crossesMonitorAtEdge;
  assert settings.borders.enabled;
  assert settings.borders.width == 1;
  assert builtins.all (rule: builtins.isString rule.bundleId) settings.appRules;
  assert builtins.all (hotkey: hotkey.binding == "Unassigned") settings.hotkeys; true
