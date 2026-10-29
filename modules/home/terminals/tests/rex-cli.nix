# Evaluate the CLI consumers without building a host configuration.
let
  appPath = "/Applications/Rex Beta.app";
  expected = "${appPath}/Contents/Helpers/Rex Server.rex/Contents/MacOS/rex";
  mkModule = isDarwin: lanEnabled: listenAddress:
    import ../rex.nix {
      config = {
        ns.terminals = {
          enable = true;
          rex = {
            inherit appPath;
            enable = true;
            lan = {
              enable = lanEnabled;
              inherit listenAddress;
            };
          };
        };
        home.homeDirectory = "/test/home";
        xdg.configHome = "/test/config";
        xdg.configFile."ghostty/config".text = "";
        lib.file.mkOutOfStoreSymlink = path: path;
      };
      lib = {
        mkIf = condition: value:
          if condition
          then value
          else {};
        mkOption = value: value;
        mkMerge = builtins.foldl' (acc: next: acc // next) {};
        hm.dag.entryAfter = _: script: script;
        types = {
          str = null;
          bool = null;
        };
        concatStringsSep = builtins.concatStringsSep;
        splitString = _: _: [];
        hasPrefix = _: _: false;
        escapeShellArg = builtins.toJSON;
        makeBinPath = _: "/test/bin";
      };
      pkgs = {
        stdenv.hostPlatform.isDarwin = isDarwin;
        writeText = _: _: "/test/theme";
        coreutils = "/test/coreutils";
        diffutils = "/test/diffutils";
        bash = "/test/bash";
      };
    };
  module = mkModule true true "0.0.0.0:7297";
  localOnly = mkModule true false "0.0.0.0:7297";
  custom = mkModule true true "192.0.2.1:8000";
  linux = mkModule false false "0.0.0.0:7297";
  contains = needle: text: builtins.replaceStrings [needle] [""] text != text;
in
  assert module.config.targets.darwin.defaults."com.superlogical.rex"."Workspace.terminalFontName" == "JetBrainsMono Nerd Font";
  assert module.config.targets.darwin.defaults."com.superlogical.rex"."Workspace.terminalFontStyle" == "Medium";
  assert module.config.targets.darwin.defaults."com.superlogical.rex"."Workspace.terminalFontPointSize" == 12.0;
  assert module.config.targets.darwin.defaults."com.superlogical.rex"."Workspace.inactivePaneFadeMode" == "none";
  assert !module.config.targets.darwin.defaults."com.superlogical.rex"."Workspace.usesStandardInactiveWindowPaneStyles";
  assert module.config.targets.darwin.defaults."com.superlogical.rex".NSUserKeyEquivalents."Hide Rex Beta" == "@$^h";
  assert module.config.targets.darwin.defaults."com.superlogical.rex".NSUserKeyEquivalents."Hide Rex" == "@$^h";
  assert !module.config.targets.darwin.defaults."com.superlogical.rex"."rex.server.tailnet-enabled";
  assert !module.config.targets.darwin.defaults."com.superlogical.rex"."rex.server.automatic-restart-enabled";
  assert module.options.ns.terminals.rex.lan.enable.default == false;
  assert module.config.launchd.agents.rex-server.config.ProgramArguments
  == [
    expected
    "server"
    "run"
    "--extra-listen"
    "0.0.0.0:7297"
    "--allow-anonymous"
  ];
  assert module.config.launchd.agents.rex-server.config.RunAtLoad;
  assert module.config.launchd.agents.rex-server.config.KeepAlive;
  assert localOnly.config.launchd.agents.rex-server == {};
  assert localOnly.config.targets.darwin.defaults."com.superlogical.rex"."rex.server.automatic-restart-enabled";
  assert builtins.elem "192.0.2.1:8000" custom.config.launchd.agents.rex-server.config.ProgramArguments;
  assert module.config.home.file.".local/bin/rex".source == expected;
  assert !contains expected module.config.xdg.configFile."rex/init.lua".text;
  assert builtins.attrNames module.config.xdg.configFile == ["rex/cycle.lua" "rex/init.lua"];
  assert module.config.xdg.configFile."rex/cycle.lua".source == ../rex/cycle.lua;
  assert linux.config.xdg.configFile."rex/cycle.lua".source == ../rex/cycle.lua;
  assert contains "rex.exec.start" module.config.xdg.configFile."rex/init.lua".text;
  assert !contains "checked(rex.exec(" module.config.xdg.configFile."rex/init.lua".text;
  assert contains "cycle_focus" module.config.xdg.configFile."rex/init.lua".text;
  assert linux.config.xdg.configFile."rex/init.lua".text == module.config.xdg.configFile."rex/init.lua".text;
  assert builtins.attrNames linux.config.xdg.configFile == ["rex/cycle.lua" "rex/init.lua"];
  assert !(linux.config ? targets);
  assert !(linux.config ? launchd);
  assert contains (builtins.toJSON expected) module.config.home.activation.rexConfigReload; true
