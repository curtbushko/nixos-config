{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.wm.niri;
  isLinux = pkgs.stdenv.isLinux;
  wallpaper = ../styles/wallpapers/3440x1440/${config.curtbushko.theme.wallpaper};
in {
  config = mkIf cfg.enable {
    systemd.user.services.swaybg = {
      Unit = {
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
        #After = [ "niri.service" ];
        Requisite = [ "graphical-session.target" ];
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
      Service = {
        Restart = "on-failure";
        ExecStart = lib.escapeShellArgs [
          (lib.getExe pkgs.swaybg)
          "--mode"
          "fill"
          "--image"
          "${wallpaper}"
        ];
      };
    };
  };
}
