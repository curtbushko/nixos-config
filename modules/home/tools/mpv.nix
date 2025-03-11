{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.tools;
in {
  config = mkIf cfg.enable {
    programs.mpv = {
      enable = true;
      config = {
        vo = "gpu";
        loop-file = "inf";
        border = "no";
      };
    };
  };
}
