{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkIf;
  cfg = config.ns.llm;
  ds4 = pkgs.callPackage ../../../packages/ds4 {};
in {
  options.ns.llm = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable llm
      '';
    };
    pi.enabledModels = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        Provider/model glob patterns exposed by Pi's model cycling interface.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
      ds4
    ];

    # Base model directory environment variable
    programs.zsh.sessionVariables = {
      LLAMA_CPP_MODEL_DIR = "${config.home.homeDirectory}/.local/share/llama-cpp/models";
    };
  };

  imports = [
    ./claude.nix
    ./codex.nix
    ./pi
    ./models/qwen.nix
  ];
}
