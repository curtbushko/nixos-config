{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.ns.services.wm;
in {
  config = mkIf cfg.enable {
    qt = {
      enable = true;
      platformTheme = "gtk2";
    };
  };
}
