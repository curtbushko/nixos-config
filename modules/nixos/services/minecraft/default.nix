{
  lib,
  ...
}:
let
  inherit (lib) types mkOption;
in
{
  options.curtbushko.services.minecraft = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable NixOS minecraft server 
      '';
    };
  };

  imports = [
    ./minecraft-server.nix
  ];
}
