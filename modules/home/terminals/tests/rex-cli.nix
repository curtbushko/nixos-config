# Evaluate the CLI consumers without building a host configuration.
let
  appPath = "/Applications/Rex Beta.app";
  expected = "${appPath}/Contents/Helpers/Rex Server.rex/Contents/MacOS/rex";
  module = import ../rex.nix {
    config = {
      ns.terminals = {
        enable = true;
        rex = {
          inherit appPath;
          enable = true;
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
      stdenv.hostPlatform.isDarwin = true;
      writeText = _: _: "/test/theme";
      coreutils = "/test/coreutils";
      diffutils = "/test/diffutils";
      bash = "/test/bash";
    };
    # Capture the CLI passed to the plugin package in the rendered init.lua.
    inputs.rex-whichkey.lib.mkPackage = args: {plugin = args.rexCli;};
  };
  contains = needle: text: builtins.replaceStrings [needle] [""] text != text;
in
  assert module.config.home.file.".local/bin/rex".source == expected;
  assert contains (builtins.toJSON expected) module.config.xdg.configFile."rex/init.lua".text;
  assert contains (builtins.toJSON expected) module.config.home.activation.rexConfigReload; true
