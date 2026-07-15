{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkIf;
  cfg = config.ns.browsers;
  isLinux = pkgs.stdenv.isLinux;
in {
  options.ns.browsers = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable browsers
      '';
    };
  };

  imports = [
    ./firefox.nix
  ];

  config = mkIf cfg.enable {
    home.packages =
      [
      ]
      ++ (lib.optionals isLinux [
        ]);
  };
}
