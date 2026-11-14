let
  flake = builtins.getFlake (toString ../../../..);
  config = flake.homeConfigurations."deck@steamdeck".config;
  aliases = config.programs.zsh.shellAliases;
  inherit (flake.inputs.nixpkgs) lib;
in
  assert config.ns.shells.primaryMonitorBus == 10;
  assert lib.hasSuffix "--bus 10" aliases.work;
  assert lib.hasSuffix "--bus 10" aliases.pc;
  assert lib.hasSuffix "--bus 10" aliases.steamdeck; true
