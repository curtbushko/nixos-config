{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.services.llm;
in {
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      cudatoolkit
    ];

  };
}
