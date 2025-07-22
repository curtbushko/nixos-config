{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.shells;
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
in {
  config = mkIf cfg.enable {
    programs.bash = {
      enable = true;
      shellOptions = [];
      historyControl = ["ignoredups" "ignorespace"];
    };
  };
}
