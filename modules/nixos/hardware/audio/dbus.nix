{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.hardware.audio;
in {
  config = mkIf cfg.enable {
    services.dbus = {
      enable = true;
      packages = [pkgs.dconf];
    };

    programs.dconf = {
      enable = true;
    };
  };
}
