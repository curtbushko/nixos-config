{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.shells;
in {
  config = mkIf cfg.enable {
    programs.nushell = {
      enable = true;
    };
  };
}
