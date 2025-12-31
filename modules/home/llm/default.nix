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

  imports = [
    ./claude.nix
  ];
}
