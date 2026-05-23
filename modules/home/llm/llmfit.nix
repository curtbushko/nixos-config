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
    # llmfit installation - find what LLMs run on your hardware
    home.packages = [
      inputs.llmfit.packages.${system}.default
    ];

    programs.zsh = {
      shellAliases = {
        lf = "llmfit";
      };
    };
  };
}
