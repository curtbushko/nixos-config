{
  config,
  lib,
  pkgs,
  ...
}: let
  isLinux = pkgs.stdenv.isLinux;
in {
  programs.rofi = {
    enable = isLinux;
    package = pkgs.rofi-wayland;
  };
}
