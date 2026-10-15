let
  preferences = enabled:
    import ../../preferences/default.nix {
      config.ns.wm.omniwm.enable = enabled;
      lib = {};
      pkgs = {};
    };
  enabledScript = (preferences true).system.activationScripts.postActivation.text;
  disabledScript = (preferences false).system.activationScripts.postActivation.text;
in
  assert builtins.length (builtins.split "<key>enabled</key><false/>" enabledScript) == 9;
  assert builtins.length (builtins.split "<key>enabled</key><true/>" disabledScript) == 9; true
