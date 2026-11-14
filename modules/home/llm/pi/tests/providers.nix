let
  flake = builtins.getFlake (toString ../../../../..);
  inherit (flake.inputs.nixpkgs) lib;
  shared = import ../../default.nix {
    inherit lib;
    config = {};
    pkgs = {};
  };
  defaults = lib.mapAttrs (_: option: option.default) shared.options.ns.llm.pi;
  homes = ../../../../../homes;
  homeConfigs = lib.concatMap (system:
    map (name: {
      inherit name system;
      module = import (homes + "/${system}/${name}/default.nix") {
        inherit lib;
        pkgs = {};
        inputs = {};
        config = {};
      };
    }) (builtins.attrNames (builtins.readDir (homes + "/${system}"))))
  (builtins.attrNames (builtins.readDir homes));
  activeHomes = builtins.filter (home: home.module.ns.llm.enable or false) homeConfigs;
  check = home: let
    cfg = home.module.ns.llm // {pi = defaults // (home.module.ns.llm.pi or {});};
    rendered =
      (import ../default.nix {
        inherit lib;
        config = {
          ns.llm = cfg;
          home.homeDirectory = "/nonexistent-pi-provider-test";
        };
        inputs = {};
        system = home.system;
        pkgs = {
          writeText = _: text: text;
          writeShellScriptBin = _: _: "/pi-npm";
          nodejs = "/node";
        };
      }).config.content;
    settings = builtins.fromJSON rendered.home.file.".pi/agent/settings.json".source;
    models = builtins.fromJSON rendered.home.file.".pi/agent/models.json".source;
    work = home.name == "curtbushko@curtbushko-K4W6XK6XND";
    providerPolicy =
      if work
      then
        settings.defaultProvider
        == "github-copilot"
        && settings.enabledModels == ["github-copilot/*"]
        && !(settings ? defaultModel)
      else
        settings.defaultProvider
        == "openai-codex"
        && settings.defaultModel == "gpt-6.1-sol"
        && builtins.elem "anthropic/*" settings.enabledModels
        && builtins.all (model: lib.hasPrefix "openai-codex/" model || lib.hasPrefix "anthropic/" model) settings.enabledModels;
    passed =
      providerPolicy
      && models.providers == {}
      && builtins.elem "-builtin:llama.cpp" settings.extensions
      && !(builtins.hasAttr "pi-local" (rendered.programs.zsh.shellAliases or {}))
      && !(builtins.hasAttr ".pi/agent/prompts/local.md" rendered.home.file);
  in
    assert lib.assertMsg passed "Pi provider policy failed for ${home.name}"; true;
in
  builtins.listToAttrs (map (home: {
      name = home.name;
      value = check home;
    })
    activeHomes)
