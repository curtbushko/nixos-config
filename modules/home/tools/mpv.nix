{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.ns.tools;
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
