{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.ns.wm.tools;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
in {
  config = mkIf cfg.enable {
    home.packages = with pkgs;
      [
      ]
      ++ (lib.optionals isLinux [
        swaylock
      ]);
  };
}
