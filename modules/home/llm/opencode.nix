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
in {
  config = mkIf cfg.enable {
    # OpenCode installation
    home.packages = [
      inputs.opencode.packages.${system}.default
    ];

    programs.zsh = {
      shellAliases = {
        ocode = "opencode";
      };
    };
  };
}
