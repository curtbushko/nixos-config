{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.wm.niri;
  isLinux = pkgs.stdenv.isLinux;
in {
  config = mkIf cfg.enable {
    services.cliphist = {
      enable = true;
      systemdTargets = ["niri.service"];
    };

    # Override systemd units to wait for niri and handle restarts gracefully
    systemd.user.services.cliphist = {
      Unit = {
        After = ["niri.service"];
        Requires = ["niri.service"];
      };
      Service = {
        RestartSec = 3;
      };
    };

    systemd.user.services.cliphist-images = {
      Unit = {
        After = ["niri.service"];
        Requires = ["niri.service"];
      };
      Service = {
        RestartSec = 3;
      };
    };
  };
}
