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
    };
    # systemd.user.services.cliphist = {
    #   Unit = {
    #     Description = "Clipboard history";
    #     BindsTo = "graphical-session.target";
    #     PartOf = "graphical-session.target";
    #     After = "graphical-session.target";
    #     Requisite = "graphical-session.target";
    #   };
    #   Service = {
    #     ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store";
    #     Restart = "on-failure";
    #   };
    #   Install.WantedBy = [ "graphical-session.target" ];
    # };
  };
}
