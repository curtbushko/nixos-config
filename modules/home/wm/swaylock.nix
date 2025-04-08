{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.wm.tools;
  isLinux = pkgs.stdenv.isLinux;
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
