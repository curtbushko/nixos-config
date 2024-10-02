{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs,
  # You also have access to your flake's inputs.
  inputs,
  # Additional metadata is provided by Snowfall Lib.
  system, # The system architecture for this host (eg. `x86_64-linux`).
  target, # The Snowfall Lib target for this system (eg. `x86_64-iso`).
  format, # A normalized name for the system target (eg. `iso`).
  virtual, # A boolean to determine whether this system is a virtual target using nixos-generators.
  systems, # An attribute map of your defined hosts.
  # All other arguments come from the module system.
  config,
  ...
}: {
  environment.systemPackages = with pkgs; [
    cudatoolkit
    ollama
  ];

  services.ollama = {
    enable = true;
    acceleration = "cuda";
    environmentVariables = {
      OLLAMA_LLM_LIBRARY = "cuda";
      OLLAMA_KEEP_ALIVE = "20m";
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
}
