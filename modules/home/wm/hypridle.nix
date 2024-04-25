{
  pkgs,
  lib,
  ...
}: let
  isLinux = pkgs.stdenv.isLinux;
  suspendScript = pkgs.writeShellScript "suspend-script" ''
    # only suspend if audio isn't
    music_running=$(${pkgs.pipewire}/bin/pw-cli i all 2>&1 | ${pkgs.ripgrep}/bin/rg running -q)
    logged_in_count=$(who | wc -l)
    # We expect 2 lines of output from `lsof -i:548` at idle: one for output headers, another for the
    # server listening for connections. More than 2 lines indicates inbound connection(s).
    afp_connection_count=$(lsof -i:548 | wc -l)
    if [[ $logged_in_count < 1 && $afp_connection_count < 3 && $music_running == 1 ]]; then
        #${pkgs.systemd}/bin/systemctl suspend
        echo "Would have suspended"
        echo "logged in users: $logged_in_count, connection count: $afp_connection_count, music_running: $music_running"
    else
        echo "Not suspending." 
        echo "logged in users: $logged_in_count, connection count: $afp_connection_count, music_running: $music_running"
    fi
  '';
in {
  # screen idle
  services.hypridle = {
    enable = isLinux;
    beforeSleepCmd = "${pkgs.systemd}/bin/loginctl lock-session";
    lockCmd = lib.getExe config.programs.hyprlock.package;

    listeners = [
      {
        timeout = 1200;
        onTimeout = suspendScript.outPath;
      }
    ];
  };
}
