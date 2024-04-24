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
  helm-nuke = pkgs.writeShellScriptBin "helm-nuke" ''
#!/bin/sh

# Description: Delete all helm things

helm ls --all --short | xargs -L1 helm delete
kubectl delete --all jobs
kubectl delete --all statefulsets
kubectl delete --all daemonsets
kubectl delete --all replicasets
kubectl delete --all deployments
kubectl delete --all services
kubectl delete --all pvc
kubectl delete --all secrets
kubectl delete ns ns1
kubectl delete ns ns2
kubectl delete ns vault
kubectl patch crd/servicedefaults.consul.hashicorp.com -p '{"metadata":{"finalizers":[]}}' --type=merge
kubectl patch crd/serviceintentions.consul.hashicorp.com -p '{"metadata":{"finalizers":[]}}' --type=merge
kubectl patch crd/ingressgateways.consul.hashicorp.com -p '{"metadata":{"finalizers":[]}}' --type=merge
kubectl patch crd/meshes.consul.hashicorp.com -p '{"metadata":{"finalizers":[]}}' --type=merge
kubectl patch crd/proxydefaults.consul.hashicorp.com -p '{"metadata":{"finalizers":[]}}' --type=merge
kubectl patch crd/serviceresolvers.consul.hashicorp.com -p '{"metadata":{"finalizers":[]}}' --type=merge
kubectl patch crd/servicerouters.consul.hashicorp.com -p '{"metadata":{"finalizers":[]}}' --type=merge
kubectl patch crd/servicesplitters.consul.hashicorp.com -p '{"metadata":{"finalizers":[]}}' --type=merge
kubectl patch crd/terminatinggateways.consul.hashicorp.com -p '{"metadata":{"finalizers":[]}}' --type=merge
kubectl patch crd/controlplanerequestlimits.consul.hashicorp.com -p '{"metadata":{"finalizers":[]}}' --type=merge
kubectl patch crd/exportedservices.consul.hashicorp.com -p '{"metadata":{"finalizers":[]}}' --type=merge
kubectl patch crd/gatewayclassconfigs.consul.hashicorp.com -p '{"metadata":{"finalizers":[]}}' --type=merge
kubectl patch crd/jwtproviders.consul.hashicorp.com -p '{"metadata":{"finalizers":[]}}' --type=merge
kubectl patch crd/meshservices.consul.hashicorp.com -p '{"metadata":{"finalizers":[]}}' --type=merge
kubectl patch crd/samenessgroups.consul.hashicorp.com -p '{"metadata":{"finalizers":[]}}' --type=merge
kubectl delete crd/servicedefaults.consul.hashicorp.com
kubectl delete crd/serviceintentions.consul.hashicorp.com
kubectl delete crd/ingressgateways.consul.hashicorp.com
kubectl delete crd/meshes.consul.hashicorp.com
kubectl delete crd/proxydefaults.consul.hashicorp.com
kubectl delete crd/serviceresolvers.consul.hashicorp.com
kubectl delete crd/servicerouters.consul.hashicorp.com
kubectl delete crd/servicesplitters.consul.hashicorp.com
kubectl delete crd/terminatinggateways.consul.hashicorp.com
kubectl delete crd/controlplanerequestlimits.consul.hashicorp.com
kubectl delete crd/exportedservices.consul.hashicorp.com
kubectl delete crd/gatewayclassconfigs.consul.hashicorp.com
kubectl delete crd/jwtproviders.consul.hashicorp.com
kubectl delete crd/meshservices.consul.hashicorp.com
kubectl delete crd/samenessgroups.consul.hashicorp.com
'';
in {
  home.packages =
  [
    helm-nuke
  ]
  ++ (lib.optionals isLinux [
    # if linux only
  ]);
}
