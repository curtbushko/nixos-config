# Evaluate server installation without fetching the private Rex input.
let
  module = import ../default.nix {
    config.ns.services.rex = {
      enable = true;
      lanAddress = "192.0.2.1";
    };
    inputs = {
      rex.nixosModules.default = {};
      sops-nix.nixosModules.sops = {};
    };
    lib = {
      mkIf = condition: value:
        if condition
        then value
        else {};
      mkEnableOption = _: {};
      mkOption = value: value;
      types.str = null;
    };
    pkgs.writeShellApplication = _: "/test/renderer";
  };
in
  assert module.config.home-manager.users.curtbushko.ns.terminals.rex.enable;
  assert !(module.config.environment ? systemPackages);
  assert module.config.services.rex.loginServer.enable; true
