{lib, ...}: let
  inherit (lib) types mkOption;
in {
  options.curtbushko.services.teleport = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable Teleport server (auth/proxy)
      '';
    };
  };

  imports = [
    ./teleport.nix
  ];
}
