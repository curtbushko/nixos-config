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
  suspend-script = pkgs.writeShellScriptBin "suspend-script" ''
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
  #imports = [
  #  inputs.hypridle.homeManagerModules.default
  #];

  home.packages = [
    suspend-script
  ];

  xdg.configFile."hypr/hypridle.conf".text = ''
    listener {
        timeout = 1200;
        onTimeout = suspend-script
    }
 '';

}
