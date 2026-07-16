{
  config,
  inputs,
  lib,
  pkgs,
  system,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.ns.llm;

  opencodeConfig = builtins.toJSON {
    provider = {
      local = {
        name = "Local LM Studio";
        npm = "@ai-sdk/openai-compatible";
        env = [];
        options = {
          apiKey = "not-needed";
          baseURL = "http://localhost:1234/v1";
        };
        models = {
          local = {
            name = "Local Model";
            tool_call = true;
            limit = {
              context = 131072;
              output = 8192;
            };
          };
        };
      };
    };
  };
in {
  config = mkIf cfg.enable {
    home.packages = [
      inputs.opencode.packages.${system}.default
    ];

    xdg.configFile."opencode/config.json".text = opencodeConfig;

    programs.zsh = {
      shellAliases = {
        ocode = "opencode";
      };
    };
  };
}
