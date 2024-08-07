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
}: {
    #imports = [
    #inputs.sops-nix.homeManagerModules.sops
    #];
  sops.defaultSopsFile = ../../../secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";
    #sops.age.keyFile = "/home/curtbushko/.config/sops/age/keys.txt";
  sops.age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";


  # this is a little more manual than I'd like but it works and is easy to grow
  # gamingrig secrets
  sops.secrets."hosts/gamingrig/mac_address" = {};
  sops.secrets."hosts/gamingrig/syncthing_id" = {};
  sops.secrets."hosts/gamingrig/tailnet_id" = {};
  # m1 secrets
  sops.secrets."hosts/m1/mac_address" = {};
  sops.secrets."hosts/m1/syncthing_id" = {};
  sops.secrets."hosts/m1/tailnet_id" = {};
  # m1-pro secrets
  sops.secrets."hosts/m1-pro/mac_address" = {};
  sops.secrets."hosts/m1-pro/syncthing_id" = {};
  sops.secrets."hosts/m1-pro/tailnet_id" = {};
}
