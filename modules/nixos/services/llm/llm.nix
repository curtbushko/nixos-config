{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.curtbushko.services.llm;
in
{
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      cudatoolkit
      ollama
    ];

    services.ollama = {
      enable = true;
      acceleration = "cuda";
      environmentVariables = {
        OLLAMA_LLM_LIBRARY = "cuda";
        OLLAMA_KEEP_ALIVE = "120m";
      };
    };
    services.open-webui = {
      enable = false;
      host = "0.0.0.0";
      port = 8080;
      environment = {
        PYDANTIC_SKIP_VALIDATING_CORE_SCHEMAS = "True";
        SCARF_NO_ANALYTICS = "True";
        ANONYMIZED_TELEMETRY = "False";
        DO_NOT_TRACK = "True";
        ENABLE_SIGNUP = "False";
        WEBUI_AUTH = "False";
      };
    };
  };
}

