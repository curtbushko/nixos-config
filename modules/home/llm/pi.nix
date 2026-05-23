{
  config,
  inputs,
  lib,
  pkgs,
  system,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.llm;
in {
  config = mkIf cfg.enable {
    # Pi.dev CLI installation
    home.packages = [
      # Pi.dev is installed via npm
      pkgs.nodejs

      inputs.pi.packages.${system}.coding-agent
    ];

    # Configure pi.dev to use llama-cpp server on gamingrig with Qwen model
    home.file.".pi/agent/models.json" = {
      text = builtins.toJSON {
        providers = {
          gamingrig = {
            label = "Qwen on gamingrig";
            baseUrl = "http://gamingrig:8080/v1";
            api = "openai-completions";
            apiKey = "not-needed";  # Required by pi.dev but llama-cpp doesn't need auth
            compat = {
              supportsUsageInStreaming = false;
              maxTokensField = "max_tokens";
            };
            models = [
              {
                id = "qwen2.5-coder-7b";
                label = "Qwen 2.5 Coder 7B";
                contextWindow = 32768;
                maxOutputTokens = 4096;
              }
            ];
          };
        };
      };
    };

    # Configure default provider and model in settings.json
    home.file.".pi/agent/settings.json" = {
      text = builtins.toJSON {
        defaultProvider = "gamingrig";
        defaultModel = "qwen2.5-coder-7b";
        checkForUpdates = false;
        telemetry = false;
        notifications = true;
      };
    };

    programs.zsh = {
      shellAliases = {
        # Convenient alias to use Qwen model on gamingrig
        pi-qwen = "pi --provider gamingrig --model qwen2.5-coder-7b";
      };
    };
  };
}
