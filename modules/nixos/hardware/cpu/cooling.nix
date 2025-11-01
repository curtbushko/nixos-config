{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.hardware.cpu;
in {
  config = mkIf cfg.enable {
  
    programs.coolercontrol = {
      enable = true;
    };
  };
}
