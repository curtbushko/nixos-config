{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hyprland.nix
    ./rofi.nix
    ./wayland.nix
  ];
}
