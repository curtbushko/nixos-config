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
  pod-security-context = pkgs.writeShellScriptBin "pod-security-context" ''
#!/bin/sh

# List all security contexts for all pods in all namespaces

kubectl get pods --all-namespaces -o go-template --template='{{range .items}}{{"Pod Name: "}}{{.metadata.name}}
    {{if .spec.securityContext}}
      PodSecurityContext:
        {{"runAsGroup: "}}{{.spec.securityContext.runAsGroup}}                               
        {{"runAsNonRoot: "}}{{.spec.securityContext.runAsNonRoot}}                           
        {{"runAsUser: "}}{{.spec.securityContext.runAsUser}}                                 {{if .spec.securityContext.seLinuxOptions}}
        {{"seLinuxOptions: "}}{{.spec.securityContext.seLinuxOptions}}                       {{end}}
    {{else}}PodSecurity Context is not set
    {{end}}{{range .spec.containers}}
    {{"container name: "}}{{.name}}
    {{"image: "}}{{.image}}{{if .securityContext}}                                      
        {{"allowPrivilegeEscalation: "}}{{.securityContext.allowPrivilegeEscalation}}   {{if .securityContext.capabilities}}
        {{"capabilities: "}}{{.securityContext.capabilities}}                           {{end}}
        {{"privileged: "}}{{.securityContext.privileged}}                               {{if .securityContext.procMount}}
        {{"procMount: "}}{{.securityContext.procMount}}                                 {{end}}
        {{"readOnlyRootFilesystem: "}}{{.securityContext.readOnlyRootFilesystem}}       
        {{"runAsGroup: "}}{{.securityContext.runAsGroup}}                               
        {{"runAsNonRoot: "}}{{.securityContext.runAsNonRoot}}                           
        {{"runAsUser: "}}{{.securityContext.runAsUser}}                                 {{if .securityContext.seLinuxOptions}}
        {{"seLinuxOptions: "}}{{.securityContext.seLinuxOptions}}                       {{end}}{{if .securityContext.windowsOptions}}
        {{"windowsOptions: "}}{{.securityContext.windowsOptions}}                       {{end}}
    {{else}}
        SecurityContext is not set
    {{end}}
{{end}}{{end}}'
'';
in {
  home.packages =
  [
    pod-security-context
  ]
  ++ (lib.optionals isLinux [
    # if linux only
  ]);
}
