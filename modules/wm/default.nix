{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hyprland.nix
    ./wayland.nix
  ];
}
