{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.wm;
  isLinux = pkgs.stdenv.isLinux;
  hyprctl = "${config.wayland.windowManager.hyprland.package}/bin/hyprctl";
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
    services.hypridle = {
      enable = isLinux;
      settings = {
        general = {
          # 2024-09-30 - try and make hypridle stable
          ignore_dbus_inhibit = true;
          ignore_systemd_inhibit = true;
        };
        listener = [
          {
            timeout = 900; # 15 mins
            on-timeout = "${hyprctl} dispatch dpms off";
            on-resume = "${pkgs.coreutils}/bin/sleep 3;WAYLAND_DISPLAY=wayland-1 ${hyprctl} dispatch dpms on || true";
          }
          {
            timeout = 2700; # 45 minutes 
            on-timeout = "${hyprctl} dispatch dpms on || true; ${pkgs.coreutils}/bin/sleep 10; ${suspend-script}/bin/suspend-script";
            on-resume = "${pkgs.coreutils}/bin/sleep 3; WAYLAND_DISPLAY=wayland-1 ${hyprctl} dispatch dpms on || true";
          }
        ];
      };
    };
  };
}
