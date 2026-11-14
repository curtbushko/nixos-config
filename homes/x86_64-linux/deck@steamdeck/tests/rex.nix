let
  flake = builtins.getFlake (toString ../../../..);
  config = flake.homeConfigurations."deck@steamdeck".config;
  packages = builtins.filter (package: (package.pname or "") == "rex") config.home.packages;
  rex = builtins.head packages;
  service = config.systemd.user.services.rex-server or {};
in
  assert builtins.length packages == 1;
  assert builtins.elem "--no-sort" rex.patchelfFlags;
  assert rex.doInstallCheck;
  assert config.ns.terminals.rex.enable;
  assert config.programs.rex-whichkey.enable;
  assert builtins.hasAttr "rex/init.lua" config.xdg.configFile;
  assert !config.ns.terminals.rex.lan.enable;
  assert (service.Install.WantedBy or []) == ["plasma-workspace.target"];
  assert service.Unit.PartOf == ["plasma-workspace.target"];
  assert service.Unit.ConditionEnvironment == "XDG_CURRENT_DESKTOP=KDE";
  assert builtins.match ".*-steamdeck-rex-server" (builtins.head service.Service.ExecStart) != null;
  assert service.Service.Restart == "on-failure"; true
