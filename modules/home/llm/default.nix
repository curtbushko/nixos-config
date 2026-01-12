{
  config,
  inputs,
  lib,
  pkgs,
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
    home.packages =
      [
        pkgs.llama-cpp
      ];
  };

  imports = [
    ./claude.nix
  ];
}
