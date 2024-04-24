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
  kubewatcher = pkgs.writeShellScriptBin "kubewatcher" ''
#!/bin/sh

# Watches the kube-system namespace and refreshes every 10 seconds 

BGREEN='\033[1;32m'       # Bold green
GREEN='\033[0;32m'        # Green
watch -t -n 10 -c "echo \"${BGREEN}  ⎈  KUBE-SYSTEM WATCHER${GREEN}\" && kubectl get pods -n kube-system"
'';
in {
  home.packages =
  [
    kubewatcher
  ]
  ++ (lib.optionals isLinux [
    # if linux only
  ]);
}
