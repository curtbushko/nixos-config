{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.wm.niri;
  suspend-script = pkgs.writeShellScriptBin "suspend-script" ''
    #!/usr/bin/env bash

    # Give people time to login before trying to shut down right away
    ${pkgs.coreutils}/bin/sleep 30

    # only suspend if audio is not running
    music_running=$(${pkgs.pipewire}/bin/pw-cli i all 2>&1 | ${pkgs.ripgrep}/bin/rg running -q)

    # only suspend if steam is not running
    steam=$(${pkgs.procps}/bin/ps -ef | ${pkgs.gnugrep}/bin/grep -i "steam.sh" | ${pkgs.gnugrep}/bin/grep -v grep | ${pkgs.coreutils}/bin/wc -l | ${pkgs.findutils}/bin/xargs )
  
    # only suspend if no ssh connections
    ssh_connection=$(${pkgs.iproute2}/bin/ss | ${pkgs.gnugrep}/bin/grep ssh | ${pkgs.gnugrep}/bin/grep ESTAB | ${pkgs.coreutils}/bin/wc -l | ${pkgs.findutils}/bin/xargs )

    # only suspend if not converting pdfs. Also, ignore grep to stop a false positive
    #convert_pdfs=$(${pkgs.procps}/bin/ps -ef | ${pkgs.gnugrep}/bin/grep -i "convert-pdfs.sh" | ${pkgs.gnugrep}/bin/grep -v grep | ${pkgs.coreutils}/bin/wc -l | ${pkgs.findutils}/bin/xargs )
 
    if [[ $music_running -eq 0 && $ssh_connection -eq 0 && $steam -eq 0 ]]; then
      ${pkgs.coreutils}/bin/sleep 10
      ${pkgs.systemd}/bin/systemctl suspend
       echo "Would have suspended"
       echo "ssh connection: $ssh_connection, convert_pdfs: $convert_pdfs, steam: $steam"
    else
       echo "Not suspending."
       echo "ssh connection: $ssh_connection, convert_pdfs: $convert_pdfs, steam $steam"
    fi
  '';
in {
  config = mkIf cfg.enable {
    services.swayidle = {
      enable = true;
      systemdTarget = "graphical-session.target";
      events = [
        {
          event = "after-resume";
          command = "${pkgs.niri} msg action power-on-monitors";
        }
      ];
      timeouts = [
        {
          timeout = 900;
          command = "${pkgs.niri} msg action power-off-monitors";
        }
        {
          timeout = 2700;
          command = ''${pkgs.coreutils}/bin/sleep 10; ${suspend-script}/bin/suspend-script'';
        }
      ];
    };
    #systemd.user.services.swayidle.Unit.ConditionEnvironment = lib.mkForce [];
    # WAYLAND_DISPLAY not set without this
    systemd.user.services.swayidle.Unit.After = lib.mkForce [ "graphical-session.target" ];
    #systemd.user.services.swayidle.Service.Environment = [ "WAYLAND_DISPLAY=wayland-1" ];
    #systemd.user.services.swayidle.Unit.After = lib.mkForce [ "niri.service" ];
  };
}
