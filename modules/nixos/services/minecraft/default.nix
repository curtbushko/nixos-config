{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkIf;
  cfg = config.curtbushko.services.minecraft;
in {
  options.curtbushko.services.minecraft = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable NixOS minecraft server
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      packwiz
    ];
  };

  imports = [
    ./minecraft-server.nix
  ];
}
