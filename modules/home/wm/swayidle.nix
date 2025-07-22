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

    # only suspend if claude is not running
    CLAUDE_RUNNING=$(${pkgs.procps}/bin/ps -ef | ${pkgs.gnugrep}/bin/grep -i "claude" | ${pkgs.gnugrep}/bin/grep -v grep | ${pkgs.coreutils}/bin/wc -l | ${pkgs.findutils}/bin/xargs )

    # only suspend if audio is not running
    MUSIC_RUNNING=$(${pkgs.pipewire}/bin/pw-cli i all 2>&1 | ${pkgs.ripgrep}/bin/rg running -q)

    # only suspend if steam is not running
    STEAM_RUNNING=$(${pkgs.procps}/bin/ps -ef | ${pkgs.gnugrep}/bin/grep -i "steam.sh" | ${pkgs.gnugrep}/bin/grep -v grep | ${pkgs.coreutils}/bin/wc -l | ${pkgs.findutils}/bin/xargs )
  
    # only suspend if no ssh connections
    SSH_CONNECTION=$(${pkgs.iproute2}/bin/ss | ${pkgs.gnugrep}/bin/grep ssh | ${pkgs.gnugrep}/bin/grep ESTAB | ${pkgs.coreutils}/bin/wc -l | ${pkgs.findutils}/bin/xargs )

    # only suspend if not converting pdfs. Also, ignore grep to stop a false positive
    #convert_pdfs=$(${pkgs.procps}/bin/ps -ef | ${pkgs.gnugrep}/bin/grep -i "convert-pdfs.sh" | ${pkgs.gnugrep}/bin/grep -v grep | ${pkgs.coreutils}/bin/wc -l | ${pkgs.findutils}/bin/xargs )
 
    if [[ CLAUDE_RUNNING -eq 0 && $MUSIC_RUNNING -eq 0 && $SSH_CONNECTION -eq 0 && $STEAM_RUNNING -eq 0 ]]; then
      ${pkgs.coreutils}/bin/sleep 10
      ${pkgs.systemd}/bin/systemctl suspend
       echo "Suspending..."
       echo "claude running: $CLAUDE_RUNNING, music running: $MUSIC_RUNNING, ssh connection: $SSH_CONNECTION, steam: $STEAM_RUNNING"
    else
       echo "Not suspending."
       echo "music running: $MUSIC_RUNNING, ssh connection: $SSH_CONNECTION, steam $STEAM_RUNNING"
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
          command = "${pkgs.niri}/bin/niri msg action power-on-monitors";
        }
      ];
      timeouts = [
        {
          timeout = 900;
          command = "${pkgs.niri}/bin/niri msg action power-off-monitors";
        }
        {
          timeout = 2700;
          command = ''${pkgs.coreutils}/bin/sleep 10; ${suspend-script}/bin/suspend-script'';
        }
      ];
    };
    systemd.user.services.swayidle.Unit.After = lib.mkForce [ "graphical-session.target" ];
  };
}
