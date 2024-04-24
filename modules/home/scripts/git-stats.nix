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
  git-stats = pkgs.writeShellScriptBin "git-stats" ''
#!/bin/bash

gstat() {
	DAYS=$1
	COUNT=$2
	FROM=$(date -v-${DAYS}d +"%d %h, %Y")
	TO=$(date +"%d %h, %Y")

	echo "Top ${COUNT}, last ${DAYS} days: (from ${FROM} to ${TO})"
	git shortlog -sn --no-merges --since="${FROM}" --before="${TO}" | grep -v 'bot' | head -${COUNT}
}

gstat "7" "5"
gstat "14" "10"
gstat "30" "10"
gstat "60" "10"
gstat "90" "10"
gstat "180" "10"
gstat "365" "20"
'';
in {
  home.packages =
  [
    git-stats
  ]
  ++ (lib.optionals isLinux [
    # if linux only
  ]);
}
