{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs,
  # You also have access to your flake's inputs.
  inputs,
  # Additional metadata is provided by Snowfall Lib.
  system, # The system architecture for this host (eg. `x86_64-linux`).
  target, # The Snowfall Lib target for this system (eg. `x86_64-iso`).
  format, # A normalized name for the system target (eg. `iso`).
  virtual, # A boolean to determine whether this system is a virtual target using nixos-generators.
  systems, # An attribute map of your defined hosts.
  # All other arguments come from the module system.
  config,
  ...
}: let
  isLinux = pkgs.stdenv.isLinux;
  hyprctl = "${config.wayland.windowManager.hyprland.package}/bin/hyprctl";
  suspend-script = pkgs.writeShellScriptBin "suspend-script" ''
     #!/bin/sh
     set -x
     # only suspend if audio isn't
     #music_running=$(${pkgs.pipewire}/bin/pw-cli i all 2>&1 | ${pkgs.ripgrep}/bin/rg running -q)
     # only suspend if no ssh connections
     ssh_connection=$(${pkgs.iproute2}/bin/ss | ${pkgs.gnugrep}/bin/grep ssh | ${pkgs.gnugrep}/bin/grep ESTAB | ${pkgs.coreutils}/bin/wc -l | ${pkgs.findutils}/bin/xargs )
     # only suspend if not converting pdfs. Also, ignore grep to stop a false positive
     convert_pdfs=$(${pkgs.procps}/bin/ps -ef | ${pkgs.gnugrep}/bin/grep -i "convert-pdfs.sh" | ${pkgs.gnugrep}/bin/grep -v grep | ${pkgs.coreutils}/bin/wc -l | ${pkgs.findutils}/bin/xargs )
     if [[ $ssh_connection -eq 0 && $convert_pdfs -eq 0 ]]; then
       ${pkgs.coreutils}/bin/sleep 10 
       ${pkgs.systemd}/bin/systemctl suspend
        echo "Would have suspended"
        echo "ssh connection: $ssh_connection, convert_pdfs: $convert_pdfs"
     else
        echo "Not suspending."
        echo "ssh connection: $ssh_connection, convert_pdfs: $convert_pdfs"
     fi
  '';
in {
  services.swayidle = {
    enable = isLinux;
    systemdTarget = "graphical-session.target";
    timeouts = [
      {
        timeout = 15 * 60;
        command = "${hyprctl} dispatch dpms off";
        resumeCommand = "${hyprctl} dispatch dpms on || true";
      }
      {
        timeout = 45 * 60;
        command = "${hyprctl} dispatch dpms on || true; ${pkgs.coreutils}/bin/sleep 10; ${suspend-script}/bin/suspend-script";
        resumeCommand = "WAYLAND_DISPLAY=wayland-1 ${hyprctl} dispatch dpms on || true";
      }
      {
        timeout = 120 * 60;
        command = "${suspend-script}/bin/suspend-script";
        resumeCommand = "${hyprctl} dispatch dpms on";
      }
    ];
  };
}
