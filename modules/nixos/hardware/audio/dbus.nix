{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.ns.hardware.audio;
in {
  config = mkIf cfg.enable {
    services.dbus.enable = true;

    programs.dconf = {
      enable = true;
    };
  };
}
