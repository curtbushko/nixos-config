let
  flake = builtins.getFlake (toString ../../../..);
  config = flake.homeConfigurations."deck@steamdeck".config;
  inherit (flake.inputs.nixpkgs) lib;
  system = "x86_64-linux";
  packages = map toString config.home.packages;
  installed = package: builtins.elem (toString package) packages;
  checks = {
    llmEnabled = config.ns.llm.enable;
    piInstalled = installed flake.inputs.pi.packages.${system}.coding-agent;
    codexInstalled = installed flake.inputs.codex-nixpkgs.legacyPackages.${system}.codex;
    claudeInstalled = config.programs.claude-code.enable && installed config.programs.claude-code.package;
    retiredToolsRemoved = builtins.all (package: !(builtins.elem (lib.getName package) ["rtk" "ccusage"])) config.home.packages;
    rtkConfigRemoved = !builtins.hasAttr "rtk/config.toml" config.xdg.configFile;
    retiredInputRemoved = !builtins.hasAttr "llm-agents" flake.inputs;
    piConfigured = builtins.hasAttr ".pi/agent/settings.json" config.home.file;
    codexSkills = builtins.hasAttr ".codex/skills" config.home.file;
    claudeSkills = builtins.hasAttr ".claude/skills" config.home.file;
    deckCodexHome = config.programs.zsh.sessionVariables.CODEX_HOME or "" == "/home/deck/.codex";
    piModelsConfigured = config.ns.llm.pi.enabledModels != [];
    noLocalModelDownloads = !config.ns.llm.models.qwen.enable;
  };
  failed = builtins.attrNames (lib.filterAttrs (_: passed: !passed) checks);
in
  assert lib.assertMsg (failed == []) "Steam Deck AI checks failed: ${lib.concatStringsSep ", " failed}"; checks
