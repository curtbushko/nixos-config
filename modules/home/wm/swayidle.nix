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
     # only suspend if audio isn't
     music_running=$(${pkgs.pipewire}/bin/pw-cli i all 2>&1 | ${pkgs.ripgrep}/bin/rg running -q)
     # only suspend if no ssh connections
     ssh_connection=$($pkgs.iproute2}/bin/ss | ${pkgs.gnugrep}/bin/grep ssh | ${pkgs.gnugrep}/bin/sh -q ESTAB)
     if [[ $ssh_connection -eq 0 && $music_running -eq 0 ]]; then
       ${pkgs.coreutils}/bin/sleep 5
       ${pkgs.systemd}/bin/systemctl suspend
    echo "Would have suspended"
    echo "ssh connection: $ssh_connection, music_running: $music_running"
     else
    echo "Not suspending."
    echo "ssh connection: $ssh_connection, music_running: $music_running"
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
        resumeCommand = "${hyprctl} dispatch dpms on";
      }
      {
        timeout = 60 * 60;
        command = "${suspend-script}/bin/suspend-script";
        resumeCommand = "${hyprctl} dispatch dpms on";
      }
      {
        timeout = 120 * 60;
        command = "${suspend-script}/bin/suspend-script";
        resumeCommand = "${hyprctl} dispatch dpms on";
      }

    ];
  };
}
