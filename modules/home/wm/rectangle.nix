{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkIf;
  cfg = config.curtbushko.wm.rectangle;
  isDarwin = pkgs.stdenv.isDarwin;

  keyCodes = {
    b = 11;
    f = 3;
    h = 4;
    i = 34;
    j = 38;
    k = 40;
    l = 37;
    m = 46;
    n = 45;
    r = 15;
    three = 20;
    u = 32;
    return = 36;
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

  cmdCtrl = modifiers.command + modifiers.control;
  cmdAlt = modifiers.command + modifiers.option;
  cmdShift = modifiers.command + modifiers.shift;
  ctrlAlt = modifiers.control + modifiers.option;

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
    targets.darwin.defaults."com.knollsoft.Rectangle" = {
      launchOnLogin = true;
      hideMenubarIcon = false;
      allowAnyShortcut = true;
      alternateDefaultShortcuts = true;
      gapSize = 5;
      subsequentExecutionMode = 1;

      leftHalf = shortcut keyCodes.h cmdCtrl;
      rightHalf = shortcut keyCodes.l cmdCtrl;
      topHalf = shortcut keyCodes.k cmdCtrl;
      bottomHalf = shortcut keyCodes.j cmdCtrl;

      leftHalfAlt = shortcut keyCodes.left cmdCtrl;
      rightHalfAlt = shortcut keyCodes.right cmdCtrl;
      topHalfAlt = shortcut keyCodes.up cmdCtrl;
      bottomHalfAlt = shortcut keyCodes.down cmdCtrl;

      topLeft = shortcut keyCodes.u cmdCtrl;
      topRight = shortcut keyCodes.i cmdCtrl;
      bottomLeft = shortcut keyCodes.n cmdCtrl;
      bottomRight = shortcut keyCodes.m cmdCtrl;

      maximize = shortcut keyCodes.f cmdAlt;
      almostMaximize = shortcut keyCodes.f cmdCtrl;
      center = shortcut keyCodes.return cmdCtrl;
      restore = shortcut keyCodes.r cmdCtrl;

      smaller = shortcut keyCodes.minus cmdShift;
      larger = shortcut keyCodes.equal cmdShift;

      firstThird = shortcut keyCodes.h cmdAlt;
      centerThird = shortcut keyCodes.k cmdAlt;
      lastThird = shortcut keyCodes.l cmdAlt;
      firstTwoThirds = shortcut keyCodes.three cmdAlt;

      topCenterSixth = shortcut keyCodes.up cmdAlt;
      bottomCenterSixth = shortcut keyCodes.down cmdAlt;

      nextDisplay = shortcut keyCodes.j cmdAlt;
      previousDisplay = shortcut keyCodes.k cmdAlt;

      reflowTodo = shortcut keyCodes.n ctrlAlt;
      toggleTodo = shortcut keyCodes.b ctrlAlt;
    };
  };
}
