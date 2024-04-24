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
  gke-delete-node = pkgs.writeShellScriptBin "gke-delete-node" ''
#!/bin/sh

# Description: Deletes a GKE node 

if [ "$1" = "" ]; then
        echo "Error: Missing node name"
        exit 1
fi

echo "Deleting GKE node: $1"


NODE="$1"
set -e
echo "Cordoning ${NODE}"
kubectl cordon "${NODE}"
echo "Draining ${NODE}"
kubectl drain "${NODE}" --force --ignore-daemonsets --delete-emptydir-data
ZONE="$(kubectl get node "${NODE}" -o jsonpath='{.metadata.labels.topology\.gke\.io/zone}')"
INSTANCE_GROUP=$(gcloud compute instances describe --zone="${ZONE}" --format='value[](metadata.items.created-by)' "${NODE}")
INSTANCE_GROUP="${INSTANCE_GROUP##*/}"

echo "Deleting instance for node '${NODE}' in zone '${ZONE}' instance group '${INSTANCE_GROUP}'"
gcloud compute instance-groups managed delete-instances --instances="${NODE}" --zone="${ZONE}" "${INSTANCE_GROUP}"
echo "Deleting instance for node '${NODE}' completed."
'';
in {
  home.packages =
  [
    gke-delete-node
  ]
  ++ (lib.optionals isLinux [
    # if linux only
  ]);
}
