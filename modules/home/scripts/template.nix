# Script Template
#
# To use:
# - Copy this template file to the new script name
# - Rename SCIPTNAME to the name of the script in the entire file
# - Insert script in between single quotes ''     ''
# - Add filename to imports section of ./scripts/default
# - If LinuxOnly script, make sure SCRIPTNAME is only in the isLinux section of home.packages

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
  SCRIPTNAME = pkgs.writeShellScriptBin "SCRIPTNAME" ''
#!/bin/bash

echo "Hello World"

'';
in {
  home.packages =
  [
    SCRIPTNAME
  ]
  ++ (lib.optionals isLinux [
    # if linux only
  ]);
}
