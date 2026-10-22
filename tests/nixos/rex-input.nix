# Snowfall's input discovery must not force the authenticated Linux Rex flake.
let
  flake = import ../../flake.nix;
  evaluate = rex:
    flake.outputs {
      inherit rex;
      snowfall-lib.mkLib = {inputs, ...}: {
        mkFlake = _: {
          discoveredRexLib = inputs.rex.lib or null;
          linuxRexModule = inputs.rex.nixosModules.default;
        };
      };
    };
  darwin = evaluate (throw "Darwin must not fetch the private Rex input");
  linux = evaluate {nixosModules.default = "linux-rex-module";};
in
  assert darwin.discoveredRexLib == null;
  assert linux.linuxRexModule == "linux-rex-module"; true
