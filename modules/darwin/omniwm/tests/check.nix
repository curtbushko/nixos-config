let
  defaults = import ../defaults.nix;
  preferences = enabled:
    import ../../preferences/default.nix {
      config.ns.wm.omniwm.enable = enabled;
      lib = {};
      pkgs = {};
    };
  enabledScript = (preferences true).system.activationScripts.postActivation.text;
  disabledScript = (preferences false).system.activationScripts.postActivation.text;
in
  assert defaults.dock.autohide;
  assert !defaults.WindowManager.GloballyEnabled;
  assert !defaults.spaces.spans-displays;
  assert defaults.trackpad.TrackpadThreeFingerHorizSwipeGesture == 0;
  assert defaults.trackpad.TrackpadFourFingerHorizSwipeGesture == 0;
  assert builtins.length (builtins.split "<key>enabled</key><false/>" enabledScript) == 9;
  assert builtins.length (builtins.split "<key>enabled</key><true/>" disabledScript) == 9; true
