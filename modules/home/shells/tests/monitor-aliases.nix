let
  aliases = isDarwin: primaryMonitorBus: let
    module = import ../zsh.nix {
      config.ns.shells = {
        enable = true;
        inherit primaryMonitorBus;
      };
      pkgs.stdenv.hostPlatform = {
        inherit isDarwin;
        isLinux = !isDarwin;
      };
      lib = {
        mkIf = condition: content:
          if condition
          then content
          else {};
        optionalAttrs = condition: content:
          if condition
          then content
          else {};
      };
    };
  in
    module.config.programs.zsh.shellAliases;
in
  assert (aliases true 5).steamdeck == "$M1DDC display 1 set input 17";
  assert (aliases false 5).steamdeck == "ddcutil setvcp $DDCUTIL_DISPLAY_INPUT $DDCUTIL_U3419W_HDMI1 --bus 5";
  assert (aliases false 10).steamdeck == "ddcutil setvcp $DDCUTIL_DISPLAY_INPUT $DDCUTIL_U3419W_HDMI1 --bus 10";
  assert (aliases false 10).work == "wakeonlan $CURTBUSHKO_K4W6XK6XND_MAC_ADDRESS; ddcutil setvcp $DDCUTIL_DISPLAY_INPUT $DDCUTIL_U3419W_USBC --bus 10";
  assert (aliases false 10).pc == "wakeonlan $GAMINGRIG_MAC_ADDRESS; ddcutil setvcp $DDCUTIL_DISPLAY_INPUT $DDCUTIL_U3419W_DP1 --bus 10"; true
