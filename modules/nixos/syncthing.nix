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
    enable = true;
    user = "curtbushko";
    dataDir = "/home/curtbushko/sync";
    configDir = "/home/curtbushko/.config/syncthing";
    settings = {
      devices = {
        "m1-pro" = {
          id = "KXFUJ3O-7Z542J6-5FQZXIB-GA26N4Z-PHMM72K-AYBFFBX-5I3NFTK-4T4KTAS";
          introducer = false;
        };
        "gamingrig" = {
          id = "GCCQHKA-DUO4WOL-NZAVYCT-TWXPJLO-75KOTPB-EQ4WQRV-PKXHKPU-LLBTEQO";
          introducer = false;
        };
        "m1-air" = {
          id = "DWSSLZC-5E6J4IT-QPBSGE2-MAAT6LR-UCRSIQZ-D4YV25W-GHRI7CK-ZSRENAY";
          introducer = false;
        };
      };
    };
  };
}
