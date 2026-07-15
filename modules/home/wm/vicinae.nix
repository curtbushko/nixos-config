{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.ns.wm.niri;
  isLinux = pkgs.stdenv.isLinux;

  # Dummy input server that does nothing (vicinae's input server needs root privileges)
  dummy-input-server = pkgs.writeShellScriptBin "vicinae-input-server" ''
    #!${pkgs.bash}/bin/bash
    # Input server disabled - requires root privileges for /dev/input access
    exit 0
  '';
in {
  imports = [
    inputs.vicinae.homeManagerModules.default
  ];

  config = mkIf cfg.enable {
    # Add packages needed for vicinae features
    home.packages = with pkgs; [
      pulseaudio # Provides pactl for audio control
    ];

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

    # Fix PATH issue for systemd service and depend on niri
    systemd.user.services.vicinae = lib.mkForce {
      Unit = {
        Description = "Vicinae Launcher Daemon";
        Documentation = "https://docs.vicinae.com";
        After = "niri.service";
        Requires = ["dbus.socket" "niri.service"];
        PartOf = "niri.service";
      };
      Service = {
        Type = "simple";
        ExecStart = "${config.home.profileDirectory}/bin/vicinae server --replace";
        ExecReload = "/bin/kill -HUP $MAINPID";
        Restart = "always";
        RestartSec = 3;
        KillMode = "mixed";
        # Ensure pactl and other tools are in PATH
        # Use dummy input server (real one requires system-level permissions for /dev/input access)
        Environment = [
          "PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin"
          "VICINAE_INPUT_SERVER_BIN=${dummy-input-server}/bin/vicinae-input-server"
        ];
      };
      Install = {
        WantedBy = ["niri.service"];
      };
    };
  };
}
