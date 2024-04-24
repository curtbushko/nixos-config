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
  makeunitwatcher = pkgs.writeShellScriptBin "makeunitwatcher" ''
#!/bin/sh

# Watches a directory for changes in files and runs go test with a clear cache 
# Requires watchexec program

BPURPLE='\033[1;35m'      # Bold purple
watchexec "echo \"${BPURPLE}   RUNNING UNIT TESTS\" && make unit"
'';
in {
  home.packages =
  [
    makeunitwatcher
  ]
  ++ (lib.optionals isLinux [
    # if linux only
  ]);
}
