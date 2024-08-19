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
  services.syncthing = {
    enable = false;
    user = "curtbushko";
    dataDir = "/home/curtbushko/sync";
    configDir = "/home/curtbushko/.config/syncthing";
    overrideDevices = true;
    overrideFolders = true;
    settings = {
      devices = {
        "m1-pro" = {
          id = config.sops.secrets."hosts/m1-pro/syncthing_id".path;
        };
        "gamingrig" = {
          id = config.sops.secrets."hosts/gamingrig/syncthing_id".path;
        };
        "m1-air" = {
          id = config.sops.secrets."hosts/m1/syncthing_id".path;
        };
      };
    };
  };
}
