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
  docker-clean = pkgs.writeShellScriptBin "docker-clean" ''
#!/bin/sh
BPURPLE='\033[1;35m' # Bold purple
GREEN='\033[0;32m'   # Green

echo "${BPURPLE}[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] Removing running containers..${GREEN}"
docker rm -f $(docker ps -a -q)

echo "${BPURPLE}[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] Removing docker images..${GREEN}"
docker image ls -q | xargs -I {} docker image rm -f {}

echo "${BPURPLE}[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] Removing volumes..${GREEN}"
docker volume rm $(docker volume ls -q)
'';
in {
  home.packages =
  [
    docker-clean
  ]
  ++ (lib.optionals isLinux [
    # if linux only
  ]);
}
