{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.wm.niri;
  isLinux = pkgs.stdenv.isLinux;
in {
  imports = [
    inputs.vicinae.homeManagerModules.default
  ];

  config = mkIf cfg.enable {
    services.vicinae = {
      enable = true;
      settings = {
         faviconService = "twenty";
         keybinding = "vim";
        #   theme.name = "vicinae-dark";
      #   window = {
      #     csd = true;
      #     opacity = 0.95;
      #     rounding = 10;
      #   };
      };
    };

    # Fix PATH issue for systemd service
    systemd.user.services.vicinae = lib.mkForce {
      Unit = {
        Description = "Vicinae Launcher Daemon";
        Documentation = "https://docs.vicinae.com";
        After = "graphical-session.target";
        Requires = "dbus.socket";
        PartOf = "graphical-session.target";
      };
      Service = {
        Type = "simple";
        ExecStart = "${config.home.profileDirectory}/bin/vicinae server --replace";
        ExecReload = "/bin/kill -HUP $MAINPID";
        Restart = "always";
        RestartSec = 60;
        KillMode = "process";
      };
      Install = {
        WantedBy = ["graphical-session.target"];
      };
    };
  };
}
