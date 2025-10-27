{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.curtbushko.wm.niri;
  isLinux = pkgs.stdenv.isLinux;
in {
  imports = [
    inputs.vicinae.homeManagerModules.default
  ];

  config = mkIf cfg.enable {

    services.vicinae = {
      enable = true;
      autoStart = true;
      # settings = {
      #   faviconService = "twenty";
      #   keybinding = "vim";
      #   theme.name = "vicinae-dark";
      #   window = {
      #     csd = true;
      #     opacity = 0.95;
      #     rounding = 10;
      #   };
      # };
    };
  };
}
