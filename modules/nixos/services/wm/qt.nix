{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.services.wm;
in {
  config = mkIf cfg.enable {
    qt = {
      enable = true;
      platformTheme = "gtk2";
    };
  };
}
