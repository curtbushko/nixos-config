{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkIf;
  cfg = config.curtbushko.wm.rectangle;
  isDarwin = pkgs.stdenv.isDarwin;

  # Key codes (from Carbon HIToolbox/Events.h)
  keyCodes = {
    h = 4;
    j = 38;
    k = 40;
    l = 37;
    f = 3;
    return = 36;
    u = 32;
    i = 34;
    n = 45;
    m = 46;
    minus = 27;
    equal = 24;
    left = 123;
    right = 124;
    up = 126;
    down = 125;
  };

  # Modifier flags
  modifiers = {
    command = 1048576;
    option = 524288;
    control = 262144;
    shift = 131072;
  };

  # Cmd+Ctrl (like niri Mod+Ctrl)
  cmdCtrl = modifiers.command + modifiers.control;
  # Cmd+Alt (like niri Mod+Alt)
  cmdAlt = modifiers.command + modifiers.option;
  # Cmd+Shift (like niri Mod+Shift)
  cmdShift = modifiers.command + modifiers.shift;

  # Helper to create a shortcut object
  shortcut = keyCode: modifierFlags: {
    inherit keyCode modifierFlags;
  };
in {
  options.curtbushko.wm.rectangle = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable Rectangle window manager configuration with niri-like keybindings
      '';
    };
  };

  config = mkIf (cfg.enable && isDarwin) {
    # Configure Rectangle via macOS defaults
    # Keybindings mapped similar to niri:
    # - Cmd+Ctrl+H/J/K/L for half-screen positions (like niri Mod+Ctrl+H/J/K/L)
    # - Cmd+Alt+F for maximize (like niri Mod+Alt+F for fullscreen)
    # - Cmd+Ctrl+U/I/N/M for quarters
    # - Cmd+Shift+Minus/Equal for smaller/larger (like niri resize)
    targets.darwin.defaults."com.knollsoft.Rectangle" = {
      # Disable default shortcuts we're overriding
      launchOnLogin = true;
      hideMenubarIcon = false;

      # Half screen positions (Cmd+Ctrl+H/J/K/L like niri Mod+Ctrl movement)
      leftHalf = shortcut keyCodes.h cmdCtrl;
      rightHalf = shortcut keyCodes.l cmdCtrl;
      topHalf = shortcut keyCodes.k cmdCtrl;
      bottomHalf = shortcut keyCodes.j cmdCtrl;

      # Also allow arrow keys (Cmd+Ctrl+Arrows)
      leftHalfAlt = shortcut keyCodes.left cmdCtrl;
      rightHalfAlt = shortcut keyCodes.right cmdCtrl;
      topHalfAlt = shortcut keyCodes.up cmdCtrl;
      bottomHalfAlt = shortcut keyCodes.down cmdCtrl;

      # Quarter positions (Cmd+Ctrl+U/I/N/M)
      topLeft = shortcut keyCodes.u cmdCtrl;
      topRight = shortcut keyCodes.i cmdCtrl;
      bottomLeft = shortcut keyCodes.n cmdCtrl;
      bottomRight = shortcut keyCodes.m cmdCtrl;

      # Maximize (Cmd+Alt+F like niri Mod+Alt+F fullscreen)
      maximize = shortcut keyCodes.f cmdAlt;

      # Center window (Cmd+Ctrl+Return)
      center = shortcut keyCodes.return cmdCtrl;

      # Resize smaller/larger (Cmd+Shift+Minus/Equal like niri Mod+Shift+Minus/Equal)
      smaller = shortcut keyCodes.minus cmdShift;
      larger = shortcut keyCodes.equal cmdShift;

      # First/Last third (Cmd+Alt+H/L like niri preset column widths)
      firstThird = shortcut keyCodes.h cmdAlt;
      lastThird = shortcut keyCodes.l cmdAlt;

      # Center third (for triple monitor or wide screen)
      centerThird = shortcut keyCodes.k cmdAlt;

      # Move to next/previous display (Cmd+Ctrl+J/K when window is at edge)
      nextDisplay = shortcut keyCodes.j cmdAlt;
      previousDisplay = shortcut keyCodes.k cmdAlt;

      # Restore to previous size (Cmd+Ctrl+R)
      restore = shortcut 15 cmdCtrl; # R = 15

      # Almost maximize (leave small margin)
      almostMaximize = shortcut keyCodes.f cmdCtrl;
    };
  };
}
