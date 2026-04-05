{
  config,
  inputs,
  lib,
  pkgs,
  system,
  ...
}: let
  inherit (lib) types mkOption mkIf;
  cfg = config.curtbushko.llm;
in {
  options.curtbushko.llm = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable llm
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
        pkgs.llama-cpp
        inputs.llm-agents.packages.${system}.rtk
        inputs.llm-agents.packages.${system}.ccusage
    ];

    # RTK config
    xdg.configFile."rtk/config.toml".source = ./rtk-config.toml;
  };

  imports = [
    ./claude.nix
  ];
}
